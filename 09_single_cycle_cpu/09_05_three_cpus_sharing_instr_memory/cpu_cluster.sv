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

module cpu_cluster
#(
    parameter nCPUs = 3
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

    wire [31:0] instrAddr [0:nCPUs - 1];
    wire [31:0] instrData ;

    logic [31:0] romAddr;

    wire [7:0] requests;
    wire [7:0] grants;

    generate
        for (genvar i = 0; i < nCPUs; ++i) begin
            sr_cpu core (
                .clk       ( clk           ), 
                .rst       ( rst           ),

                .rstPC     ( rstPC     [i] ), 

                .imAddr    ( instrAddr [i] ),
                .imData    ( instrData     ),
                .imDataVld ( grants    [i] ),

                .regAddr   ( regAddr   [i] ),
                .regData   ( regData   [i] ) 
            );
            assign requests[i] = 1'b1;
        end
    endgenerate

    assign requests[7:nCPUs] = '0;

    round_robin_arbiter_8 arbiter (
        .clk ( clk      ),
        .rst ( rst      ),
        .req ( requests ),
        .gnt ( grants   )
    );

    always_comb begin
        romAddr = '0;
        case (grants) 
            8'b0000_0001: romAddr = instrAddr[0];
            8'b0000_0010: romAddr = instrAddr[1];
            8'b0000_0100: romAddr = instrAddr[2];
            8'b0000_1000: romAddr = instrAddr[3];
            8'b0001_0000: romAddr = instrAddr[4];
            8'b0010_0000: romAddr = instrAddr[5];
            8'b0100_0000: romAddr = instrAddr[6];
            8'b1000_0000: romAddr = instrAddr[7];
        endcase
    end
    
    instruction_rom rom (
        .a  ( romAddr   ),
        .rd ( instrData )
    );


endmodule
