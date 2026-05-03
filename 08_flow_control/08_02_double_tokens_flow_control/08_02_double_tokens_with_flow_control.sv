//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

  // Task:
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;
 
  // Solution:

  localparam int MAX_PENDING = 100;

  logic [7:0] pending_outputs;

  assign up_ready   = (pending_outputs < (MAX_PENDING * 2));
  assign down_valid = 1'b1;
  assign down_data  = (pending_outputs > 0) ? 1'b1 : up_token & up_valid;

  always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
          pending_outputs <= 8'd0;
      end else begin
          case ({up_valid && up_ready, down_valid && down_ready})
              2'b10: begin 
                  if (up_token)
                      pending_outputs <= pending_outputs + 8'd2;
              end
              
              2'b01: begin
                  pending_outputs <= (pending_outputs > 0) ? pending_outputs - 8'd1 : pending_outputs;
              end
              
              2'b11: begin
                  if (up_token)
                      pending_outputs <= pending_outputs + 8'd1;
                  else
                      pending_outputs <= (pending_outputs > 0) ? pending_outputs - 8'd1 : pending_outputs;
              end
              
              default: ;
          endcase
      end
  end

endmodule
