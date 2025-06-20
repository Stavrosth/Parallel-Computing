`timescale 1ns/1ps

module FSM_testbench;
    reg reset, clk;
    reg [31:0] instruction;
    reg [31:0] immediate;
    reg [31:0] curr_PC;
    reg mispredict;
    wire block_signal;
    wire flush;
    wire [31:0] new_pc;
    wire [31:0] out_instruction;

    simpleFSM mlk(
        .clk(clk),
        .reset(reset),
        .curr_PC(curr_PC),
        .instruction(instruction),
        .immediate(immediate),  
        .block_signal(block_signal),
        .mispredict(mispredict),
        .flush(flush),
        .new_pc(new_pc),
        .out_instruction(out_instruction)
    );

    always
        #5 clk = ~clk;

    initial begin
        clk=1'b1;
        reset=1'b0;
        immediate=32'b0;
        mispredict = 1'b0;
        #10 reset = 1'b0;
        #10 reset = 1'b1;
// #1000
        // Test cases can be added here
        // For example, you can toggle the reset signal and observe the FSM behavior

        // for (integer i = 0; i < 20; i = i + 1) begin
        //     #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP at 0x100
        //     #10 curr_PC = 32'h00000104; instruction = 32'h00000014; // NOP at 0x104
        //     #10 curr_PC = 32'h00000108; instruction = 32'h00000015; // NOP at 0x108
        //     #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;  

        //     if (i == 4 || i == 8) begin
        //         mispredict = 1'b1; // Set mispredict signal
        //         #10 mispredict = 1'b0;
        //     end
       // end
        #100
        #10 curr_PC = 32'h00000100; instruction = 32'h00000013; immediate = -0;// NOP at 0x100
        #10 curr_PC = 32'h00000104; instruction = 32'h00000014; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000108; instruction = 32'h00000015; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;
        #10 curr_PC = 32'h00000100; instruction = 32'h00000013; immediate = -0;// NOP at 0x100
        #10 curr_PC = 32'h00000104; instruction = 32'h00000014; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000108; instruction = 32'h00000015; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;
        #10 curr_PC = 32'h00000100; instruction = 32'h00000013; immediate = -0;// NOP at 0x100
        #10 curr_PC = 32'h00000104; instruction = 32'h00000014; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000108; instruction = 32'h00000015; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;
        #10 instruction = 32'b0;// immediate=32'b0;// NOP at 0x100
        
        #150 mispredict = 1'b1; // Wait for some time before the next iteration
        #10 curr_PC = 32'h00000110; instruction = 32'h00000016; immediate = -0; mispredict = 1'b0; // NOP at 0x100
        #10 curr_PC = 32'h00000114; instruction = 32'h00000017; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000118; instruction = 32'h00000018; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000011C; instruction = 32'hFC000AE3; immediate = -3;
        #10 curr_PC = 32'h00000110; instruction = 32'h00000016; immediate = -0;// NOP at 0x100
        #10 curr_PC = 32'h00000114; instruction = 32'h00000017; immediate = -0;// NOP at 0x104
        #10 curr_PC = 32'h00000118; instruction = 32'h00000018; immediate = -0;// NOP at 0x108
        #10 curr_PC = 32'h0000011C; instruction = 32'hFC000AE3; immediate = -3; 
        #10 curr_PC = 32'h0; instruction = 32'h0; immediate = 0;// NOP at 0x100
        #50 mispredict = 1'b1;
        #10 mispredict = 1'b1;
        #100 $finish; // End simulation after some time
    end

endmodule