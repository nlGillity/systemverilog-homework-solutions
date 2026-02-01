module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    // Solution:

    localparam NUM_MODULES   = 32;
    localparam ADDRESS_WIDTH = $clog2(NUM_MODULES);

    /* -------------------------- Arbiter logic -------------------------- */

    logic [ADDRESS_WIDTH - 1:0] exec_ptr;

    always_ff @(posedge clk)
             if ( rst     ) exec_ptr <= '0;
        else if ( arg_vld ) exec_ptr <= exec_ptr + 1'b1;

    logic [ADDRESS_WIDTH - 1:0] read_ptr;

    always_ff @(posedge clk)
             if ( rst         ) read_ptr <= '0;
        else if ( |output_vld ) read_ptr <= read_ptr + 1'b1;

    /* ---------- Input/output signals and registers of modules ---------- */

    logic [NUM_MODULES - 1:0] input_vld;

    // TODO: redesign input_vld
    always_ff @(posedge clk)
        if (rst) input_vld           <= '0; 
        else     input_vld[exec_ptr] <= arg_vld;

    logic [31:0] input_a [0:NUM_MODULES - 1];
    logic [31:0] input_b [0:NUM_MODULES - 1];
    logic [31:0] input_c [0:NUM_MODULES - 1];

    always_ff @(posedge clk) begin
        if (arg_vld) begin
            input_a[exec_ptr] <= a;
            input_b[exec_ptr] <= b;
            input_c[exec_ptr] <= c;
        end
    end

    logic [NUM_MODULES - 1:0] output_vld;
    logic [             31:0] output_res  [0:NUM_MODULES - 1];

    /* ------------- Creating instances of specified modules ------------- */

    generate
        genvar i;

        // Modules for processing formula 1
        if (formula == 1) begin : instances_formula_1
            if (impl == 1) begin : instances_impl_1
                for (i = 0; i < NUM_MODULES; i++) begin
                    formula_1_impl_1_top inst (
                        .clk     ( clk            ),
                        .rst     ( rst            ),

                        .arg_vld ( input_vld  [i] ),
                        .a       ( input_a    [i] ),
                        .b       ( input_b    [i] ),
                        .c       ( input_c    [i] ),

                        .res_vld ( output_vld [i] ),
                        .res     ( output_res [i] )
                    );
                end
            end : instances_impl_1

            else if (impl == 2) begin : instances_impl_2
                for (i = 0; i < NUM_MODULES; i++) begin
                    formula_1_impl_2_top inst (
                        .clk     ( clk            ),
                        .rst     ( rst            ),

                        .arg_vld ( input_vld  [i] ),
                        .a       ( input_a    [i] ),
                        .b       ( input_b    [i] ),
                        .c       ( input_c    [i] ),

                        .res_vld ( output_vld [i] ),
                        .res     ( output_res [i] )
                    );
                end
            end : instances_impl_2
        end : instances_formula_1

        // Modules for processing formula 2
        else if (formula == 2) begin : instances_formula_2
            for (i = 0; i < NUM_MODULES; i++) begin
                formula_2_top inst (
                    .clk     ( clk            ),
                    .rst     ( rst            ),

                    .arg_vld ( input_vld  [i] ),
                    .a       ( input_a    [i] ),
                    .b       ( input_b    [i] ),
                    .c       ( input_c    [i] ),

                    .res_vld ( output_vld [i] ),
                    .res     ( output_res [i] )
                );
            end
        end
    endgenerate

    /* --------------------------- Output logic -------------------------- */

    assign res_vld = |output_vld;
    assign res     = output_res[read_ptr];

endmodule
