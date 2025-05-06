module FSM_testbench;
    reg reset, clk;
    reg mispredict;
    reg [31:0] immediate; //immediate from branch instructions
    reg [31:0] curr_PC; //the PC this moment, taken directly from IFID
    reg [31:0] instruction; //32-bit instruction from IFID
    wire [31:0] new_pc;
    wire block_signal, flush, reuse_signal;

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
        .instruction(instruction)
    );

    always
        #1 clk = ~clk;

    initial begin
        clk=1'b0;
        reset=1'b0;
        mispredict=1'b0;
        #5 instruction = 32'b00000000000000000000000000001111; // Example instruction
        #10 instruction = 32'b00000000000000000000000001101111; // JAL instruction
            immediate = -10; 
            curr_PC = 32'h00000020; // Example current PC value
        #10 curr_PC = 32'h00000000; // Example current PC value
            instruction = 32'b00000000000000000000000000001111;
        #10 curr_PC = 32'h00000004; // Example current PC value
        #10 curr_PC = 32'h00000008; // Example current PC value
        #10 curr_PC = 32'h00000020; // Example current PC value
            instruction = 32'b00000000000000000000000001101111;
        #50 mispredict = 1'b1; // Set mispredict signal 
        $finish;
    end

endmodule