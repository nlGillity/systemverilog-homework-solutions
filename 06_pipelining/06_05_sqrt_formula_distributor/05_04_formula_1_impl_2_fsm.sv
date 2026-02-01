//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm 

    // // -------------------------- FSM logic --------------------------

    // enum logic [2:0] {
    //     IDLE      = 3'b000,
    //     LOAD_AB   = 3'b001,
    //     LOAD_C    = 3'b010,
    //     CALCED_AB = 3'b011,
    //     FINALIZE  = 3'b100
    // } state, next_state;

    // always_ff @(posedge clk)
    //     if (rst) state <= IDLE;
    //     else     state <= next_state;

    // always_comb begin
    //     next_state = state;

    //     case (state)
    //         IDLE      : if (arg_vld)       next_state = LOAD_AB;
    //         LOAD_AB   :                    next_state = LOAD_C;
    //         LOAD_C    : if (isqrt_1_y_vld) next_state = CALCED_AB;
    //         CALCED_AB : if (isqrt_1_y_vld) next_state = FINALIZE;
    //         FINALIZE  :                    next_state = IDLE;
    //     endcase
    // end

    // // ------------ isqrt module control signal logic ---------------

    // always_comb begin
    //     isqrt_1_x_vld = 1'b0;
    //     isqrt_2_x_vld = 1'b0;

    //     isqrt_1_x = a;
    //     isqrt_2_x = b;

    //     case (state)
    //         IDLE: 
    //             if (arg_vld) begin
    //                 isqrt_1_x_vld = 1'b1;
    //                 isqrt_2_x_vld = 1'b1;
    //             end
    //         LOAD_AB: 
    //             begin
    //                 isqrt_1_x_vld = 1'b1;
    //                 isqrt_1_x     = c;
    //             end
    //     endcase
    // end

    // // --------------------------------------------------------------

    // logic [31:0] reg_1, reg_2;

    // always_ff @(posedge clk)
    //     if (rst) 
    //         reg_1 <= '0;
    //     else if (arg_vld)
    //         reg_1 <= '0;
    //     else if (isqrt_1_y_vld)
    //         reg_1 <= isqrt_1_y;

    // always_ff @(posedge clk)
    //     if (rst) 
    //         reg_2 <= '0;
    //     else if (arg_vld)
    //         reg_2 <= '0;
    //     else if (isqrt_2_y_vld)
    //         reg_2 <= isqrt_2_y;


    // logic [31:0] result;

    // always_ff @(posedge clk)
    //     if (rst)
    //         result <= '0;
    //     else if (arg_vld)
    //         result <= '0;
    //     else if (isqrt_1_y_vld)
    //         result <= result + reg_1 + reg_2;

    // logic completed;
    // assign completed = (state == FINALIZE);

    // assign res_vld = completed;
    // assign res     = completed ? result + reg_1 : 'b0;

    // -------------------------------------------------------------------------

    enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD_AB = 2'b01,
        LOAD_C  = 2'b10,
        FINAL   = 2'b11
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = state;

        case (state)
            IDLE    : if (arg_vld)       next_state = LOAD_AB; 
            LOAD_AB : if (isqrt_1_y_vld) next_state = LOAD_C;
            LOAD_C  : if (isqrt_1_y_vld) next_state = FINAL;
            FINAL   :                    next_state = IDLE;
        endcase
    end

    always_comb begin
        isqrt_1_x_vld = 1'b0;
        isqrt_1_x     = '0;

        isqrt_2_x_vld = 1'b0;
        isqrt_2_x     = '0;

        case (state)
            IDLE:
                if (arg_vld) begin
                    isqrt_1_x_vld = 1'b1;
                    isqrt_1_x     = a;

                    isqrt_2_x_vld = 1'b1;
                    isqrt_2_x     = b;
                end

            LOAD_AB:
                if (isqrt_1_y_vld) begin
                    isqrt_1_x_vld = 1'b1;
                    isqrt_1_x     = c;
                end
        endcase
    end

    logic [31:0] sum;
    always_ff @(posedge clk)
        if (rst) 
            sum <= '0;
        else if (arg_vld)
            sum <= '0;
        else if (isqrt_1_y_vld)
            sum <= sum + isqrt_1_y + ( isqrt_2_y_vld ? isqrt_2_y : '0 );

    assign res_vld = state == FINAL;
    assign res     = sum;

endmodule
