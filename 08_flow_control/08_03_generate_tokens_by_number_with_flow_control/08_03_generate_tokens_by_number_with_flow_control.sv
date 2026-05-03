//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.

    logic [WIDTH - 1:0] clip_ff; 
    logic               in_process_ff;

    wire   is_empty;
    assign is_empty = ~(|clip_ff);

    wire   is_blocked;
    assign is_blocked = ~down_ready;

    wire   reload;
    assign reload = up_valid & up_ready;

    always_ff @(posedge clk) begin: ammunition_clip_logic
        if ( reload ) 
            clip_ff <= n_tokens;
        else if ( ~is_blocked )
            clip_ff <= clip_ff - 1'b1;
    end

    always_ff @(posedge clk) begin
             if ( rst                      ) in_process_ff <= '0;
        else if ( reload                   ) in_process_ff <= '1;
        else if ( in_process_ff & is_empty ) in_process_ff <= '0;
    end

    assign up_ready   = ~in_process_ff;
    assign down_token = ~is_empty;
    assign down_valid = in_process_ff;


endmodule
