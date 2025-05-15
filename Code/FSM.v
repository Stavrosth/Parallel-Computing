module stream_loop_detector(new_pc, flush, block_signal, reset, clk, immediate, curr_PC, mispredict, instruction, out_instruction);
    input reset, clk, mispredict;
    input signed [31:0] immediate; //immediate from branch instructions
    input [31:0] curr_PC; //the PC this moment, taken directly from IF/ID
    input [31:0] instruction; //32-bit instruction from IF/ID
    output reg [31:0] new_pc;
    output reg block_signal, flush;
    reg read_enable;
    reg [1:0] current_state, next_state, pc_reg_change;
    reg [31:0] main_branch_pc;
    output [31:0] out_instruction;
    // BRAM signals
    reg write_enable, buff_start;
    reg [5:0] write_address, read_address;

    //FSM STATES
    parameter TRACK = 2'b00,   
              BUFFERING = 2'b01, 
              REUSE = 2'b10, 
              RESET = 2'b11;

    /*** remove this when implemented to RISC V ***/
    //then we will get the opcode from the include file 
    parameter JAL_OPCODE=  7'b1101111,
              BTYPE_OPCODE=7'b1100011,
              JALR_OPCODE= 7'b1100111;

    parameter LOOP_SIZE = -27; //number of instructions able to be stored in the bram

    //FSM sequential block
    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            current_state <= TRACK;
        end else begin
            current_state <= next_state;
        end
    end  

    //FSM combination block (state changing)
    always @(*) begin
        // Sets values here in order to avoid latches
        next_state = current_state;
        flush = 1'b0;
        block_signal = 1'b0;
        read_enable = 1'b0;
        write_enable = 1'b0;
        pc_reg_change = 2'b0;
        
        case (current_state)
            TRACK: begin                                                                   // immediate<0 and loop_size<0 so we must imm>=loop_size
                if((instruction[6:0] == BTYPE_OPCODE || instruction[6:0] == JAL_OPCODE) && (immediate[31]==1'b1) && (immediate>=LOOP_SIZE)) begin//we used to have mispredict here too!!!
                    pc_reg_change = 2'b01;
                    next_state = BUFFERING;
                end else begin
                    next_state = TRACK;
                end
            end
            BUFFERING: begin
                if(instruction[6:0] == BTYPE_OPCODE || instruction[6:0] == JAL_OPCODE) begin //check that loop is a basic block
                    if (main_branch_pc != curr_PC) begin // make sure the branch is not the one of our loop
                        next_state = RESET;
                    end
                    else begin
                        pc_reg_change = 2'b10;
                        block_signal = 1'b1;
                        next_state = REUSE;
                    end
                end
                else begin
                    write_enable = 1'b1; // here because write_address +=1 when we==1
                    next_state = BUFFERING;
                end
            end
            REUSE:begin
                block_signal = 1'b1;
                if(mispredict == 1'b1) begin
                    flush = 1'b1;
                    next_state = RESET;
                end else begin
                    read_enable = 1'b1;
                    next_state = REUSE;
                end
            end
            RESET: begin
                flush = 1'b1;
                next_state = TRACK;
            end
            default: begin 
                flush = 1'b0;
                block_signal = 1'b0;
                read_enable = 1'b0;
                write_enable = 1'b0;
                pc_reg_change = 2'b0;
                next_state = TRACK;
            end
        endcase
    end

    //If the FSM finds detects a branch it saves its PC for future use
    //else it just leaves the main branch pc to 0
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            main_branch_pc <= 32'd0;
            new_pc <= 32'd0;
        end else if (pc_reg_change[0] == 1'b1) begin
            main_branch_pc <= curr_PC;
        end else if (pc_reg_change[1] == 1'b1) begin
            new_pc <= main_branch_pc + 4;
        end
    end

    //Always block that manages read signals for bram
    always @(posedge clk or posedge reset) begin
        if(reset == 1'b1) begin
            read_address <= 6'd0;
        end else if(read_enable == 1'b0) begin
            read_address <= 6'd0;
        end else begin
            if (main_branch_pc == curr_PC) begin
                read_address <= 6'd0;
            end else begin
                read_address <= read_address + 6'd8;
            end
        end
    end

    //Always block that manages write signals for bram
    always @(posedge clk or posedge reset) begin
        if(reset == 1'b1) begin
            write_address <= 6'd0;
        end else if(write_enable == 1'b1) begin
            write_address <= write_address + 6'd8;
        end else begin
            write_address <= 6'd0;
        end
    end

    // Accesses Bram
    uop_cache bram(.clk(clk), .reset(reset), .instruction(instruction), .read_enable(read_enable), .write_enable(write_enable), .read_address(read_address), .write_address(write_address), .out_instruction(out_instruction));

endmodule