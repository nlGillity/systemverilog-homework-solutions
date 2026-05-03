//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab #(parameter int FLEN = 64) (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array #(parameter int FLEN = 64) (
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats_impl#(parameter int FLEN = 64, parameter int NE = 11) (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res2
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic u0_less_or_equal_u1, u1_less_or_equal_u2, u0_less_or_equal_u2;
    logic err0, err1, err2;

    f_less_or_equal i_floe_01
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err0                )
    );

    f_less_or_equal i_floe_12
    (
        .a   ( unsorted [1]        ),
        .b   ( unsorted [2]        ),
        .res ( u1_less_or_equal_u2 ),
        .err ( err1                )
    );

    f_less_or_equal i_floe_02
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [2]        ),
        .res ( u0_less_or_equal_u2 ),
        .err ( err2                )
    );

    always_comb
        case ({ u0_less_or_equal_u1, u1_less_or_equal_u2, u0_less_or_equal_u2 })
            3'b111: sorted = {unsorted[0], unsorted[1], unsorted[2]};
            3'b101: sorted = {unsorted[0], unsorted[2], unsorted[1]};
            3'b100: sorted = {unsorted[2], unsorted[0], unsorted[1]};
            3'b000: sorted = {unsorted[2], unsorted[1], unsorted[0]};
            3'b010: sorted = {unsorted[1], unsorted[2], unsorted[0]};
            3'b011: sorted = {unsorted[1], unsorted[0], unsorted[2]};
        endcase

    assign err = err0 | err1 | err2;

endmodule


// --- compatibility wrapper for batch testing ---
module sort_three_floats #(
  parameter int FLEN = 64,
  parameter int NE   = 11
) (
  input  [FLEN-1:0] a,
  input  [FLEN-1:0] b,
  input  [FLEN-1:0] c,
  output [FLEN-1:0] res0,
  output [FLEN-1:0] res1,
  output [FLEN-1:0] res2,
  output            err
);
  wire [0:2][FLEN-1:0] unsorted;
  wire [0:2][FLEN-1:0] sorted;

  assign unsorted = {a, b, c};

  sort_three_floats_impl u_impl (
    .unsorted(unsorted),
    .sorted(sorted),
    .err(err)
  );

  assign res0 = sorted[0];
  assign res1 = sorted[1];
  assign res2 = sorted[2];
endmodule
// --- end compatibility wrapper ---


// --- support: f_less_or_equal.sv ---
// Helper module for IEEE-754 FP64 ordered compare a <= b (no NaN/Inf handling here).
// If a or b is NaN/Inf, err=1 and res is still driven deterministically.

module f_less_or_equal
#(
  parameter FLEN = 64,
  parameter NE   = 11
)
(
  input  [FLEN - 1:0] a,
  input  [FLEN - 1:0] b,
  output              res,
  output              err
);
  wire sign_a = a[FLEN - 1];
  wire sign_b = b[FLEN - 1];

  wire [NE - 1:0] exp_a = a[FLEN - 2 -: NE];
  wire [NE - 1:0] exp_b = b[FLEN - 2 -: NE];

  wire a_is_err = (exp_a === {NE{1'b1}});
  wire b_is_err = (exp_b === {NE{1'b1}});
  assign err = a_is_err | b_is_err;

  wire a_is_zero = (a[FLEN - 2:0] === { (FLEN - 1){1'b0} });
  wire b_is_zero = (b[FLEN - 2:0] === { (FLEN - 1){1'b0} });
  wire both_zeros = a_is_zero & b_is_zero;

  wire [FLEN - 2:0] mag_a = a[FLEN - 2:0];
  wire [FLEN - 2:0] mag_b = b[FLEN - 2:0];

  wire same_bits = (a === b);

  wire a_le_b;
  assign a_le_b =
    both_zeros ? 1'b1 :
    same_bits  ? 1'b1 :
    (sign_a ^ sign_b) ? (sign_a ? 1'b1 : 1'b0) :
    (sign_a == 1'b0) ? (mag_a <= mag_b) :
                       (mag_a >= mag_b);

  assign res = a_le_b;
endmodule
