//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.

    // Solution:

    logic [2 * width - 1:0] buffer_data_ff;
    logic [            1:0] valid_ff;

    localparam MAX   = 2 * width - 1;
    localparam MIDLE = width; 

    wire enable;
    assign enable = up_ready & up_valid;

    wire content;
    assign content = |valid_ff;

    always_ff @(posedge clk) begin
        if ( enable ) buffer_data_ff <= up_data;
    end

    always_ff @(posedge clk) begin
             if ( rst        ) valid_ff <= 2'b0;
        else if ( enable     ) valid_ff <= 2'b1;
        else if ( down_ready ) valid_ff <= { valid_ff[0], enable };  
    end

    logic counter_ff;
    always_ff @(posedge clk) begin
        if ( rst | enable                 ) counter_ff <= '0;
        else if ( content & down_ready ) counter_ff <= ~counter_ff;
    end

    assign up_ready   = ~content; 
    assign down_valid = content;
    assign down_data  = counter_ff ? buffer_data_ff[MIDLE:0] : buffer_data_ff[MAX:MIDLE];


endmodule
