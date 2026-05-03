//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.

    // Solution:

    logic [width-1:0] data_reg;
    logic             valid_reg;
    logic             has_pending_data;

    assign up_ready = down_ready || !has_pending_data;

    always_ff @(posedge clock) begin
        if (reset) begin
            data_reg         <= '0;
            has_pending_data <= 1'b0;
        end else begin
            if (up_valid && up_ready) begin
                data_reg         <= up_data;
                has_pending_data <= 1'b1;
            end else if (down_valid && down_ready) begin
                has_pending_data <= 1'b0;
            end
        end
    end

    assign down_data  = data_reg;
    assign down_valid = has_pending_data && (up_valid || !up_ready); 
    

    assign down_last  = up_valid && up_first;


endmodule
