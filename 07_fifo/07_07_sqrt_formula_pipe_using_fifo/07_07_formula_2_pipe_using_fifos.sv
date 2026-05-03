//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    // Solution:

    localparam isqrt_stages = 5; 
    localparam num_stages   = 3;
    localparam last_stage   = num_stages - 1;

    // ISQRT's wires
    wire [num_stages - 1:0] sqrt_vld;
    wire [            31:0] sqrt_res [0:num_stages - 1];

    // FIFO outputs
    wire [31:0] fifo_res [0:num_stages - 2];

    // Buffer registers (cutting critical path)
    logic [0:num_stages - 1] reg_vld;
    logic [            31:0] reg_res [0:num_stages - 1];

    always_ff @(posedge clk) begin: vld_buffer_regs
        if (rst) reg_vld <= '0;

        for (int i = 0; i < num_stages; i++)
            reg_vld[i] <= sqrt_vld[i];
    end

    always_ff @(posedge clk) begin: res_buffer_regs
        if (sqrt_vld[last_stage]) 
            reg_res[last_stage] <= sqrt_res[last_stage];

        for (int i = 0; i < num_stages - 1; i++)
            if (sqrt_vld[i]) reg_res[i] <= sqrt_res[i] + fifo_res[i];
    end

    // ------------------------- FIFO modules -------------------------

    flip_flop_fifo_with_counter #(
        .width(32), .depth(isqrt_stages)
    ) fifo_b (
        .clk        ( clk          ),
        .rst        ( rst          ),

        .push       ( arg_vld      ),
        .pop        ( sqrt_vld [0] ),

        .write_data ( b            ),
        .read_data  ( fifo_res [0] ),

        .empty      (              ),
        .full       (              )
    );

    flip_flop_fifo_with_counter #(
        .width(32), .depth(2 * isqrt_stages + 1)
    ) fifo_a (
        .clk        ( clk          ),
        .rst        ( rst          ),

        .push       ( arg_vld      ),
        .pop        ( sqrt_vld [1] ),

        .write_data ( a            ),
        .read_data  ( fifo_res [1] ),

        .empty      (              ),
        .full       (              )
    );

    // ------------------------- ISQRT modules -------------------------

    isqrt #(
        .n_pipe_stages(isqrt_stages)
    ) isqrt_a (
        .clk   ( clk          ),
        .rst   ( rst          ),

        .x_vld ( arg_vld      ),
        .x     ( c            ),

        .y_vld ( sqrt_vld [0] ),
        .y     ( sqrt_res [0] )
    );

    isqrt #(
        .n_pipe_stages(isqrt_stages)
    ) isqrt_bc (
        .clk   ( clk          ),
        .rst   ( rst          ),

        .x_vld ( reg_vld  [0] ),
        .x     ( reg_res  [0] ),

        .y_vld ( sqrt_vld [1] ),
        .y     ( sqrt_res [1] )
    );

    isqrt #(
        .n_pipe_stages(isqrt_stages)
    ) isqrt_abc (
        .clk   ( clk          ),
        .rst   ( rst          ),

        .x_vld ( reg_vld  [1] ),
        .x     ( reg_res  [1] ),

        .y_vld ( sqrt_vld [2] ),
        .y     ( sqrt_res [2] )
    );

    // ----------------------------------------------------------------

    assign res_vld = reg_vld[last_stage];
    assign res     = reg_res[last_stage];


endmodule
