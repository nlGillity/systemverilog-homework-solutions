//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.

    // Solution:

    logic [width - 1:0] buffer_ff [0:1];
    logic [        1:0] valid_ff;

    assign full   = &valid_ff;
    assign enable = up_valid & up_ready;

    always @(posedge clk) begin
        if ( enable ) begin
            buffer_ff[1] <= buffer_ff[0];
            buffer_ff[0] <= up_data;
        end
    end

    always @(posedge clk) begin
             if ( rst    ) valid_ff <= '0;
        else if ( full & down_ready  ) valid_ff <= up_valid;
        else if ( enable ) valid_ff <= { valid_ff[0], 1'b1 };
    end

    assign up_ready   = ~full | full & down_ready;
    assign down_valid = full;
    assign down_data  = { buffer_ff[1], buffer_ff[0] };


endmodule
