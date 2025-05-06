// questions:
//     -> do we need jalr or just jal

module stream_loop_detector(new_pc, flush, block_signal, reuse_signal, reset, clk, immediate, curr_PC, mispedict, instruction);
    input reset, clk;
    input mispedict;
    signed input [31:0] immediate; //immediate from branch instructions
    input [31:0] curr_PC; //the PC this moment, taken directly from IFID
    input [31:0] instruction; //32-bit instruction from IFID
    reg [1:0] current_state, next_state;
    reg reuse_signal;
    reg [31:0] main_branch_pc;//the position of the branch we use for our loop
    output reg [31:0] new_pc;
    output reg block_signal, flush;

    //FSM STATES
    parameter TRACK = 2'b00, BUFFERING = 2'b01, REUSE = 2'b10, RESET = 2'b11;

    //remove this when implemented to RISC V
    //then we will get the opcode from the include file 
    parameter JAL_OPCODE=  7'b1101111,
              BTYPE_OPCODE=7'b1100011,
              JALR_OPCODE= 7'b1100111;

    //loop size (instructions) in order to be suitable for loop buffering
    parameter LOOP_SIZE = -27;
    
    //FSM sequential block
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            block_signal <= 1'b0;
            flush <= 1'b0;
            reuse_signal <= 1'b0;
            current_state <= TRACK;
        end else
            current_state <= next_state;
    end  

    //FSM combination block (state changing)
    always @(current_state) begin
        case (current_state)
            TRACK: begin 
                if(instruction[6:0] == JAL_OPCODE || instruction[6:0] == BTYPE_OPCODE || instruction[6:0] == JALR_OPCODE) begin
                    // immediate<0 and loop_size<0 so we must imm>=loop_size
                    if((immediate<0) && (immediate>=LOOP_SIZE)) begin
                        main_branch_pc = curr_PC; // stores the position of the branch we use for our loop
                        next_state = BUFFERING;
                    end
                end else
                    next_state = current_state;
            end
            BUFFERING: begin
                if(instruction[6:0] == JAL_OPCODE || instruction[6:0] == BTYPE_OPCODE || instruction[6:0] == JALR_OPCODE) begin //check that loop is a basic bloc
                    if (main_branch_pc != curr_PC)// make sure the branch is not the one of our loop
                        next_state = RESET;
                    else begin
                        block_signal = 1'b1;
                        new_pc= main_branch_pc+4;
                        next_state = REUSE;
                    end
                end else
                    next_state = current_state;
            end
            REUSE:begin
                if(mispredict == 1'b1) begin
                    block_signal = 1'b0;
                    flush = 1'b1;
                    reuse_signal = 1'b0;
                    next_state = RESET;
                end else begin
                    reuse_signal = 1'b1;
                    next_state = current_state;
                end
            end
            RESET: begin
                // RESETS BRAM
                flush = 1'b0;
                next_state = TRACK;
            end
            default: next_state = TRACK;
        endcase
    end

    /**
     * Always block with reuse signal that accesses BRAM
     */

endmodule