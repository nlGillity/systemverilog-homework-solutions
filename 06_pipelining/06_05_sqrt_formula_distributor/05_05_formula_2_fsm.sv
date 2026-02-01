//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // Task:
    //
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    enum logic [1:0] {
        IDLE       = 2'b00,
        LOAD_C     = 2'b01,
        LOAD_SUM_B = 2'b10,
        LOAD_SUM_A = 2'b11
    } state, next_state;

    always_ff @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next_state;

    always_comb begin
        next_state = state;

        case (state)
            IDLE       : if (arg_vld)     next_state = LOAD_C; 
            LOAD_C     : if (isqrt_y_vld) next_state = LOAD_SUM_B;
            LOAD_SUM_B : if (isqrt_y_vld) next_state = LOAD_SUM_A;
            LOAD_SUM_A : if (isqrt_y_vld) next_state = IDLE;
        endcase
    end

    logic completed;
    assign completed = (state == LOAD_SUM_A) & isqrt_y_vld;

    always_comb begin
        isqrt_x_vld = 1'b0;
        isqrt_x     = '0;

        case (state)
            IDLE:
                if (arg_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = c;
                end
            LOAD_C:
                if (isqrt_y_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = b + isqrt_y;
                end
            LOAD_SUM_B:
                if (isqrt_y_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = a + isqrt_y;
                end
        endcase
    end

    assign res_vld = completed;
    assign res     = completed ? isqrt_y : 'b0;

endmodule
