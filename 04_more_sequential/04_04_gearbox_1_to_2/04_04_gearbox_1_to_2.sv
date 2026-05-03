//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    logic               prev_vld;
    logic [width - 1:0] prev_data;

    always_ff @(posedge clk)
        if (rst) begin
            prev_vld  <= 1'b0;
            prev_data <= width'(0);
        end
        else if (down_vld) begin
            prev_vld  <= 1'b0;
            prev_data <= width'(0);
        end
        else if (up_vld) begin
            prev_vld  <= 1'b1;
            prev_data <= up_data;
        end

    assign down_vld  = up_vld & prev_vld;
    assign down_data = { prev_data, up_data };

endmodule
