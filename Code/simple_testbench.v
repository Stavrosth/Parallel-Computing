`timescale 1ns/1ps

module FSM_testbench;
    reg reset, clk;
    reg [31:0] instruction;
    reg [31:0] immediate;
    reg [31:0] curr_PC;
    reg mispredict, bubble_idex;
    wire block_signal;
    wire flush;
    wire [31:0] new_pc;
    wire [31:0] out_instruction;

    simpleFSM loop_detector(
        .clk(clk),
        .reset(reset),
        .curr_PC(curr_PC),
        .instruction(instruction),
        .immediate(immediate),  
        .block_signal(block_signal),
        .mispredict(mispredict),
        .flush(flush),
        .new_pc(new_pc),
        .out_instruction(out_instruction),
        .bubble_idex(bubble_idex)
    );

    always
        #5 clk = ~clk;

    initial begin
        clk=1'b1;
        reset=1'b0;
        immediate=32'b0;
        mispredict = 1'b0;
        bubble_idex = 1'b0;
        #10 reset = 1'b0;
        #10 reset = 1'b1;
        
        #100 // First loop
        #10 curr_PC = 32'h00000100; instruction = 32'h00000013; immediate = -0;// NOP at 0x100
        #10 curr_PC = 32'h00000104; instruction = 32'h00000014; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000108; instruction = 32'h00000015; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -12; 
        #10 instruction = 32'h1;// Simulates the 4 ` of delay present in the Risc-v 
        #10 instruction = 32'h2;// Simulates the 4 instructions of delay present in the Risc-v
        #10 instruction = 32'h0;// Simulates the 4 instructions of delay present in the Risc-v
        #10 instruction = 32'h0;// Simulates the 4 instructions of delay present in the Risc-v
        #10 curr_PC = 32'h00000100; instruction = 32'h00000013; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h00000104; instruction = 32'h00000014; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h00000108; instruction = 32'h00000015; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -12;// issued again in order to buffer the instructions
        #10 instruction = 32'b0;
        #150 mispredict = 1'b1; // Wait till some iterations of this loop happen
        
        // Second loop
        #10 curr_PC = 32'h00000110; instruction = 32'h00000016; immediate = -0; mispredict = 1'b0; // NOP at 0x100
        #10 curr_PC = 32'h00000114; instruction = 32'h00000017; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000118; instruction = 32'h00000018; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000011C; instruction = 32'hFC000AE3; immediate = -12;
        #10 instruction = 32'h1;// Simulates the 4 instructions of delay present in the Risc-v
        #10 instruction = 32'h2;// Simulates the 4 instructions of delay present in the Risc-v
        #10 instruction = 32'h0;// Simulates the 4 instructions of delay present in the Risc-v
        #10 instruction = 32'h0;// Simulates the 4 instructions of delay present in the Risc-v
        #10 curr_PC = 32'h00000110; instruction = 32'h00000016; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h00000114; instruction = 32'h00000017; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h00000118; instruction = 32'h00000018; immediate = -0;// issued again in order to buffer the instructions
        #10 curr_PC = 32'h0000011C; instruction = 32'hFC000AE3; immediate = -12;// issued again in order to buffer the instructions 
        #10 curr_PC = 32'h0; instruction = 32'h0; immediate = 0;// NOP at 0x100
        #50 mispredict = 1'b1;
        #10 mispredict = 1'b0;
        #100 $finish; // End simulation after some time
    end

endmodule