//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    // Solution:

    logic res_ready;

    /* ---------------------- FSM describtion --------------------- */

    enum logic [1:0] {
        IDLE      = 2'b00,
        LOADED_A  = 2'b01,
        LOADED_B  = 2'b10,
        LOADED_C  = 2'b11
    } state, next_state;

    // FSM state change logic:

    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;

        case (state)
            IDLE      : if ( arg_vld   ) next_state = LOADED_A;
            LOADED_A  :                  next_state = LOADED_B;
            LOADED_B  :                  next_state = LOADED_C;
            LOADED_C  : if ( res_ready ) next_state = IDLE;
        endcase
    end

    /* ----------------- ISQRT input signals logic ---------------- */

    always_comb begin
        isqrt_x_vld = 1'b0;
        isqrt_x     = '0;
        
        case(state)
            IDLE:
                begin: choose_a
                    isqrt_x_vld = arg_vld;
                    isqrt_x = a;
                end

            LOADED_A:
                begin: choose_b
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = b;
                end

            LOADED_B:
                begin: choose_c
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = c;
                end
        endcase
    end

    /* ------------------------- Data path ------------------------ */

    localparam TERMS = 3;

    // Valid-registers

    logic [TERMS - 1:0] buffer_vld;

    always_ff @(posedge clk) begin
        if (rst | res_vld) 
            buffer_vld <= '0;
        else
            buffer_vld <= { buffer_vld[TERMS - 2:0], isqrt_y_vld };
    end

    // Data-registers

    logic [17:0] buffer_data [0:TERMS - 1];

    always_ff @(posedge clk) begin
        if (isqrt_y_vld) 
            buffer_data[0] <= isqrt_y;

        for (int i = 1; i < TERMS; i++)
            if (buffer_vld[i - 1]) 
                buffer_data[i] <= buffer_data[i - 1] + isqrt_y;
    end

    assign res_ready = buffer_vld  [TERMS - 1];
    assign res_vld   = res_ready;
    assign res       = buffer_data [TERMS - 1];


endmodule
