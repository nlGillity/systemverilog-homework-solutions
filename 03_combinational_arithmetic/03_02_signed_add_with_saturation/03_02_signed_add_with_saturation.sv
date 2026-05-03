//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module signed_add_with_saturation
(
  input  [3:0] a, b,
  output [3:0] sum
);

  // Task:
  //
  // Implement a module that adds two signed numbers with saturation.
  //
  // "Adding with saturation" means:
  //
  // When the result does not fit into 4 bits,
  // and the arguments are positive,
  // the sum should be set to the maximum positive number.
  //
  // When the result does not fit into 4 bits,
  // and the arguments are negative,
  // the sum should be set to the minimum negative number.

  logic [3:0] addition;
  assign addition = a + b;

  logic overflow;
  assign overflow = (addition[3] & ~a[3] & ~b[3]) | (~addition[3] & a[3] & b[3]);

  logic [3:0] result;
  always_comb begin
    result = addition;

    if (overflow)
      case ({a[3], b[3]})
        2'b00: result = 4'b0111;
        2'b11: result = 4'b1000;
      endcase
  end

  assign sum = result;

endmodule
