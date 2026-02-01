//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    // Solution:

    localparam WIDTH = 32;
    localparam DEPTH = 16;

    /* ----------- Shift registers for aligning terms ------------- */

    logic [31:0] term_a, term_b;

    shift_register_with_valid #(
        .width    ( WIDTH   ),
        .depth    ( DEPTH   )
    ) shift_term_b (
        .clk      ( clk     ),
        .rst      ( rst     ),

        .in_vld   ( arg_vld ),
        .in_data  ( b       ),

        .out_vld  (         ),
        .out_data ( term_b  )
    );

    shift_register_with_valid #(
        .width    ( WIDTH       ),
        .depth    ( 2*DEPTH + 1 )
    ) shift_term_a (
        .clk      ( clk     ),
        .rst      ( rst     ),

        .in_vld   ( arg_vld ),
        .in_data  ( a       ),

        .out_vld  (         ),
        .out_data ( term_a  )
    );

    // -----------------------------------------------------

    logic [31:0] sqrt_c,     sqrt_bc,     sqrt_abc;
    logic        sqrt_c_vld, sqrt_bc_vld, sqrt_abc_vld;

    logic [31:0] buffer_bc, buffer_abc;

    always_ff @(posedge clk) 
        if (sqrt_c_vld) buffer_bc <= term_b + sqrt_c;

    always_ff @(posedge clk) 
        if (sqrt_bc_vld) buffer_abc <= term_a + sqrt_bc;

    /* -------- Intermediate regs between ISQRT modules -------- */

    logic reg_sqrt_c_vld,  // saves: sqrt(c) 
          reg_sqrt_bc_vld; // saves: sqrt(b + sqrt(c))

    always_ff @(posedge clk)
        if (rst) reg_sqrt_c_vld <= 1'b0;
        else     reg_sqrt_c_vld <= sqrt_c_vld;
    
    always_ff @(posedge clk)
        if (rst) reg_sqrt_bc_vld <= 1'b0;
        else     reg_sqrt_bc_vld <= sqrt_bc_vld;

    // ------------------------------------------------------

    isqrt #(
        .n_pipe_stages ( DEPTH )
    ) isqrt_c (
        .clk   ( clk        ),
        .rst   ( rst        ),

        .x_vld ( arg_vld    ),
        .x     ( c          ),

        .y_vld ( sqrt_c_vld ),
        .y     ( sqrt_c     )       /* sqrt(c) */
    );

    isqrt #(
        .n_pipe_stages ( DEPTH )
    ) isqrt_bc (
        .clk   ( clk            ),
        .rst   ( rst            ),

        .x_vld ( reg_sqrt_c_vld ),
        .x     ( buffer_bc      ),

        .y_vld ( sqrt_bc_vld    ),
        .y     ( sqrt_bc        )   /* sqrt(b + sqrt(c)) */
    );

    isqrt #(
        .n_pipe_stages ( DEPTH )
    ) isqrt_abc (
        .clk   ( clk             ),
        .rst   ( rst             ),

        .x_vld ( reg_sqrt_bc_vld ),
        .x     ( buffer_abc      ),

        .y_vld ( sqrt_abc_vld    ), 
        .y     ( sqrt_abc        )  /* sqrt(a + sqrt(b + sqrt(c))) */
    );

    // ------------------------------------------

    assign res_vld = sqrt_abc_vld;
    assign res     = sqrt_abc;

endmodule
