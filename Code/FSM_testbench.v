`timescale 1ns/1ps

module FSM_testbench;
    reg reset, clk;
    reg mispredict;
    reg [31:0] immediate; //immediate from branch instructions
    reg [31:0] curr_PC; //the PC this moment, taken directly from IFID
    reg [31:0] instruction; //32-bit instruction from IFID
    wire [31:0] new_pc;
    wire block_signal, flush, reuse_signal;
    wire [31:0] out_instruction;
    integer i;

    // Instantiate the FSM module
    stream_loop_detector LSD (
        .new_pc(new_pc),
        .flush(flush),
        .block_signal(block_signal),
        .reset(reset),
        .clk(clk),
        .immediate(immediate),
        .curr_PC(curr_PC),
        .mispredict(mispredict),
        .instruction(instruction),
        .out_instruction(out_instruction)
    );

    always
        #5 clk = ~clk;

    initial begin
        clk=1'b1;
        reset=1'b0;
        mispredict=1'b0;
        immediate=32'b0;
        #10 reset = 1'b1;
        #10 reset = 1'b0;

        // #5 instruction = 32'b00000000000000000000000000001111; // Example instruction
        // #5 instruction = 32'b00000000000000000000000001100011; // BRANCH instruction
        //     immediate = -10; 
        //     curr_PC = 32'h00000020; // Example current PC value
        // #5 curr_PC = 32'h00000000; // Example current PC value
        //     instruction = 32'b00000000000000000000000000001111;
        // #5 curr_PC = 32'h00000004; // Example current PC value
        // #5 curr_PC = 32'h00000008; // Example current PC value
        // #5 curr_PC = 32'h00000020; // Example current PC value
        //     instruction = 32'b00000000000000000000000001100011;
        // #50 mispredict = 1'b1; // Set mispredict signal 
        // #5 mispredict=1'b0;

        // $display("[%0t] Starting loop iteration 1", $time);
        for (i = 0; i < 20; i = i + 1) begin
            #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP at 0x100
            #10 curr_PC = 32'h00000104; instruction = 32'h00000014; // NOP at 0x104
            #10 curr_PC = 32'h00000108; instruction = 32'h00000015; // NOP at 0x108
            #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;  

            if (i == 4 || i == 8) begin
                mispredict = 1'b1; // Set mispredict signal
                #10 mispredict = 1'b0;
            end
        end
        // #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP at 0x100
        // #10 curr_PC = 32'h00000104; instruction = 32'h00000014; // NOP at 0x104
        // #10 curr_PC = 32'h00000108; instruction = 32'h00000015; // NOP at 0x108
        // #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;  // BEQ x0,x0,-12 (branch to 0x100)

        // // Iteration 2
        // // $display("[%0t] Starting loop iteration 2", $time);
        // #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000104; instruction = 32'h00000014; // NOP
        // #10 curr_PC = 32'h00000108; instruction = 32'h00000015; // NOP
        // #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;// BEQ (branch to 0x100)

        // // // Iteration 3 (Loop detector should be learning or have learned the loop)
        // $display("[%0t] Starting loop iteration 3", $time);
        // #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;// BEQ (branch to 0x100)

        // // // Iteration 4 (Loop detector might be streaming instructions now)
        // // $display("[%0t] Starting loop iteration 4 - expecting detector to be active", $time);
        // #10 curr_PC = 32'h00000100; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h0000010C; instruction = 32'hFC000AE3; immediate = -3;// BEQ (branch to 0x100)

        #20 mispredict = 1'b1; // Set mispredict signal 
        #10 mispredict=1'b0;

        // #10 curr_PC = 32'h00000104; instruction = 32'h00000013; // NOP
        // #10 curr_PC = 32'h00000108; instruction = 32'h00000013; // NOP
        #100 $finish;

        
    end

endmodule