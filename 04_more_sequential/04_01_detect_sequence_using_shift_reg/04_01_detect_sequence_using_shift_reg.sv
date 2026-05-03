//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_shift_reg
(
  input  clk,
  input  rst,
  input  new_bit,
  output detected
);

  // Detection of the "1010" sequence using shift register

  logic [3:0] shift_reg;

  assign detected =   shift_reg[3] &
                    ~ shift_reg[2] &
                      shift_reg[1] &
                    ~ shift_reg[0];

  always_ff @ (posedge clk)
    if (rst)
      shift_reg <= '0;
    else
      shift_reg <= {shift_reg[2:0], new_bit };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_shift_reg
(
  input  clk,
  input  rst,
  input  new_bit,
  output detected
);
  // Task:
  // Implement a module that detects the "110011" sequence

  logic [5:0] seq;

  always_ff @(posedge clk)
    if (rst)
      seq <= '0;
    else
      seq <= { new_bit, seq[5:1] };

  assign detected =   seq[0] &
                      seq[1] &
                    ~ seq[2] &
                    ~ seq[3] &
                      seq[4] &
                      seq[5];

endmodule
