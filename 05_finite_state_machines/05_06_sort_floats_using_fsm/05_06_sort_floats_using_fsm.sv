//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    // --------------------------- FSM logic ---------------------------

    enum logic [1:0] {
        IDLE     = 2'b00,
        COMPED_A_B = 2'b01,
        COMPED_B_C = 2'b10,
        COMPED_A_C = 2'b11
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = state;
        
        case (state)
            IDLE       : if (valid_in) next_state = COMPED_A_B;
            COMPED_A_B :               next_state = COMPED_B_C;
            COMPED_B_C :               next_state = COMPED_A_C;
            COMPED_A_C :               next_state = IDLE;
        endcase
    end

    // ------------ Compare module control signal logic ---------------

    always_comb begin
        case (state)
            IDLE:
                if (valid_in) begin
                    // Compare A and B
                    f_le_a = unsorted[0];
                    f_le_b = unsorted[1];
                end
            COMPED_A_B:
                begin
                    // Compare B and C
                    f_le_a = unsorted[1];
                    f_le_b = unsorted[2];
                end
            COMPED_B_C:
                begin
                    // Compare A and C
                    f_le_a = unsorted[0];
                    f_le_b = unsorted[2];
                end 
        endcase
    end

    // ------------------------------------------------------------------
    
    logic was_error;

    always_ff @(posedge clk)
        if (rst)
            was_error <= '0;
        else if (state == COMPED_A_C)
            was_error <= '0;
        else if (f_le_err)
            was_error <= 1'b1;

    logic a_le_b, b_le_c;

    always_ff @(posedge clk)
        if (rst)
            { a_le_b, b_le_c } <= 2'b0;
        else if (state == IDLE)
            a_le_b <= f_le_res;
        else if (state == COMPED_A_B)
            b_le_c <= f_le_res;
    
    // -------------------------- Output logic -------------------------

    assign busy = state != IDLE;

    always_comb begin
        case ({ a_le_b, b_le_c, f_le_res })
            3'b000  : sorted = { unsorted[2], unsorted[1], unsorted[0] };
            3'b010  : sorted = { unsorted[1], unsorted[2], unsorted[0] };
            3'b011  : sorted = { unsorted[1], unsorted[0], unsorted[2] }; 
            3'b100  : sorted = { unsorted[2], unsorted[0], unsorted[1] };
            3'b101  : sorted = { unsorted[0], unsorted[2], unsorted[1] }; 
            3'b110  : sorted = { unsorted[2], unsorted[0], unsorted[1] };
            3'b111  : sorted = { unsorted[0], unsorted[1], unsorted[2] };
            default : sorted = { unsorted[0], unsorted[1], unsorted[2] };
        endcase
    end

    assign err       = was_error;
    assign valid_out = state == COMPED_A_C;

endmodule
