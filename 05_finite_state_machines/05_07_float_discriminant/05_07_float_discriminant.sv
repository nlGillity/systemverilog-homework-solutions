//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    localparam [FLEN - 1:0] four = 64'h4010_0000_0000_0000;

    logic [FLEN - 1:0] buffer;    // storage for b^2 (res of mult2)
    logic              was_error; // any error from FPU submodules?

    // ------------------- External module connection ---------------------

    logic [FLEN - 1:0] mult1_a, mult1_b, mult1_res;
    logic              mult1_busy, mult1_error, mult1_ready, mult1_valid;
    
    f_mult mult1 (
        .clk        ( clk         ),
        .rst        ( rst         ),

        .up_valid   ( mult1_valid ),
        .a          ( mult1_a     ),
        .b          ( mult1_b     ),

        .res        ( mult1_res   ),
        .down_valid ( mult1_ready ),
        .busy       ( mult1_busy  ),
        .error      ( mult1_error )
    );

    logic [FLEN - 1:0] mult2_a, mult2_b, mult2_res;
    logic              mult2_busy, mult2_error, mult2_ready, mult2_valid;

    f_mult mult2 (
        .clk        ( clk         ),
        .rst        ( rst         ),

        .up_valid   ( mult2_valid ),
        .a          ( mult2_a     ),
        .b          ( mult2_b     ),

        .res        ( mult2_res   ),
        .down_valid ( mult2_ready ),
        .busy       ( mult2_busy  ),
        .error      ( mult2_error )
    );

    logic [FLEN - 1:0] sub_a, sub_b, sub_res;
    logic              sub_busy, sub_error, sub_ready, sub_valid;

    f_sub sub1 (
        .clk        ( clk       ),
        .rst        ( rst       ),

        .up_valid   ( sub_valid ),
        .a          ( sub_a     ),
        .b          ( sub_b     ),

        .res        ( sub_res   ),
        .down_valid ( sub_ready ),
        .busy       ( sub_busy  ),
        .error      ( sub_error )
    );

    // -------------------------- FSM logic ----------------------------

    enum logic [1:0] {
        IDLE       = 2'b00,
        MULT_BB_AC = 2'b01,
        MULT_4AC   = 2'b10,
        SUB        = 2'b11
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = state;

        case (state)
            IDLE       : if ( arg_vld     ) next_state = MULT_BB_AC;
            MULT_BB_AC : if ( mult1_ready ) next_state = MULT_4AC;
            MULT_4AC   : if ( mult1_ready ) next_state = SUB;
            SUB        : if ( sub_ready   ) next_state = IDLE;
        endcase   
    end

    // ------------------- Control signals for FPU ---------------------

    always_comb begin
        mult1_valid = 1'b0;
        mult2_valid = 1'b0;
        sub_valid   = 1'b0;

        case (state)
            IDLE:
                // Calc b^2 and a*c
                if (arg_vld) begin
                    mult1_valid = 1'b1;
                    mult1_a     = a;
                    mult1_b     = c;

                    mult2_valid = 1'b1;
                    mult2_a     = b;
                    mult2_b     = b;
                end

            MULT_BB_AC:
                // Calc 4*a*c; b^2 was remembered in buffer
                if (mult1_ready) begin
                    mult1_valid = 1'b1;
                    mult1_a     = four;
                    mult1_b     = mult1_res;
                end

            MULT_4AC:
                // Calc b^2 - 4*a*c
                if (mult1_ready) begin
                    sub_valid = 1'b1;
                    sub_a     = buffer;
                    sub_b     = mult1_res;
                end
        endcase
    end

    // -----------------------------------------------------------------

    logic finalized;
    assign finalized = state == SUB & sub_ready;

    always_ff @(posedge clk) 
        if (rst)
            buffer <= '0;
        else if (mult2_ready)
            buffer <= mult2_res;

    always_ff @(posedge clk)
        if (rst)
            was_error <= 1'b0;
        else if (finalized)
            was_error <= 1'b0;
        else if (mult1_error | mult2_error | sub_error)
            was_error <= 1'b1;

    // ------------------------- Output logic -------------------------
            
    assign res_vld      = finalized;
    assign res          = sub_res;
    assign err          = finalized ? was_error : 1'b0;
    assign busy         = state != IDLE;
    assign res_negative = sub_res[ $left(sub_res) ];

endmodule
