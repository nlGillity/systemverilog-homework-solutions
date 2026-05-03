//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "sr_cpu.svh"

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst, 

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);

    localparam int WIDTH         = 32;
    localparam int HALF_WIDTH    = WIDTH / 2; 
    localparam int PARTIAL_WIDTH = WIDTH + HALF_WIDTH;

    wire [PARTIAL_WIDTH - 1:0] ps0_delayed;
    wire [PARTIAL_WIDTH - 1:0] ps1_delayed;
    wire [    WIDTH / 2 - 1:0] srcA_delayed;
    wire [        WIDTH - 1:0] srcB_delayed;
    
    // ==============================================================
    // Stage 0
    // ==============================================================

    logic [WIDTH - 1:0] pp0 [0:PARTIAL_WIDTH - 1];

    generate
        for (genvar i = 0; i < WIDTH / 2; ++i)
            assign pp0[i] = ({ WIDTH{srcB[i]} } & srcA) << i;
    endgenerate

    logic [PARTIAL_WIDTH - 1:0] ps0;

    always_comb begin
        ps0 = '0;
        for (int i = 0; i < WIDTH / 2; ++i)
            ps0 += pp0[i];
    end
    
    shift_register #(
        .width    ( PARTIAL_WIDTH ),
        .depth    ( 2             )
    ) partial_buffer_1 (
        .clk      ( clk           ),
        .in_data  ( ps0           ),
        .out_data ( ps0_delayed   )
    );

    // ---------------------------------------------------------------

    shift_register #(
        .width    ( WIDTH / 2                 ),
        .depth    ( 1                         )
    ) srcA_buffer (
        .clk      ( clk                       ),
        .in_data  ( srcB[WIDTH - 1:WIDTH / 2] ),
        .out_data ( srcB_delayed              )
    );

    shift_register #(
        .width    ( WIDTH        ),
        .depth    ( 1            )
    ) srcB_buffer (
        .clk      ( clk          ),
        .in_data  ( srcA         ),
        .out_data ( srcA_delayed )
    );

    // ==============================================================
    // Stage 1
    // ==============================================================

    logic [WIDTH - 1:0] pp1 [0:PARTIAL_WIDTH - 1];

    generate
        for (genvar i = 0; i < WIDTH / 2; ++i)
            assign pp1[i] = ({ WIDTH{srcA_delayed[i]} } & srcB_delayed) << i;
    endgenerate

    logic [PARTIAL_WIDTH - 1:0] ps1;

    always_comb begin
        ps1 = '0;
        for (int i = 0; i < WIDTH / 2; ++i)
            ps1 += pp1[i];
    end
    
    shift_register #(
        .width    ( PARTIAL_WIDTH ),
        .depth    ( 1             )
    ) partial_buffer_2 (
        .clk      ( clk           ),
        .in_data  ( ps1           ),
        .out_data ( ps1_delayed   )
    );

    // ==============================================================
    // Stage 2
    // ==============================================================

    assign result = ps0_delayed + (ps1_delayed << 1);

    // ==============================================================
    // Valid-Busy
    // ==============================================================

    logic [n_delay - 1:0] valid_buffer;

    always_ff @(posedge clk)
        if (rst) valid_buffer <= '0;
        else     valid_buffer <= { valid_buffer[0], i_vld };

    assign o_vld = valid_buffer[n_delay - 1];
    assign busy  = (valid_buffer[0] | i_vld) & ~valid_buffer[1];
 
endmodule

//----------------------------------------------------------------------------

module shift_register
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule

