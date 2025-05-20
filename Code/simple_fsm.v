module simpleFSM(
    clk,
    reset,
    curr_PC,
    instruction, 
    immediate,
    block_signal,
    mispredict,
    flush,
    new_pc,
    out_instruction
    );
    
    input clk;
    input reset;
    input [31:0] instruction; //32-bit instruction from IF/ID
    input [31:0] immediate; //immediate value from IF/ID
    input [31:0] curr_PC;
    input mispredict;
    output reg block_signal;
    output reg flush;
    output reg [31:0] new_pc;
    reg [1:0] current_state, next_state;
    reg [31:0] main_branch_pc;
    reg change_main_pc;
    reg read_enable, write_enable;
    output [31:0] out_instruction;
    
    reg [5:0] write_address, read_address;

    wire [6:0] opcode = instruction[6:0];
    // wire [6:0] out_opcode = out_instruction[6:0];
    wire last_bit_immediate = immediate[31];
    wire mispredict_signal = mispredict;
    reg must_reset;
    wire goto_buffering;
    
    parameter TRACK = 2'b00,    
              BUFFERING = 2'b01, 
              REUSE = 2'b10, 
              RESET = 2'b11;

    /*** remove this when implemented to RISC V ***/
    //then we will get the opcode from the include file 
    parameter JAL_OPCODE =  7'b1101111,
              BTYPE_OPCODE = 7'b1100011;
              //JALR_OPCODE = 7'b1100111;

    parameter LOOP_SIZE = -27;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= TRACK;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        block_signal = 1'b0;
        flush = 1'b0;
        read_enable = 1'b0;
        write_enable = 1'b0;
        
        case (current_state)
            TRACK: begin
               if(goto_buffering) begin
                    change_main_pc = 1'b1;
                    next_state = BUFFERING;
                end else begin
                    change_main_pc = 1'b0;
                    next_state = TRACK;
                end
            end
            BUFFERING: begin
                change_main_pc = 1'b1;
                write_enable = 1'b1;

                if(opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) begin //check that loop is a basic block
                    if (must_reset) begin // make sure the branch is not the one of our loop
                        next_state = RESET;
                    end
                    else begin
                        block_signal = 1'b1;
                        next_state = REUSE;
                    end
                end
                else begin
                    next_state = BUFFERING;
                end
            end
            REUSE: begin
                change_main_pc = 1'b1;
                block_signal = 1'b1;
                if(mispredict_signal == 1'b1) begin
                    flush = 1'b1;
                    next_state = RESET;
                end else begin
                    read_enable = 1'b1;
                    next_state = REUSE;
                end
            end
            RESET: begin
                flush = 1'b1;
                change_main_pc = 1'b0;
                next_state = TRACK;
            end
            default: begin 
                change_main_pc = 1'b0;
                flush = 1'b0;
                next_state = TRACK;
            end
        endcase
    end

    // In case we detect a subloop
    assign goto_buffering = ((opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) && (last_bit_immediate == 1'b1) && (immediate >= LOOP_SIZE)) ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        if(change_main_pc == 1'b0) begin
            main_branch_pc <= curr_PC;
        end

        if (main_branch_pc != curr_PC) begin
            must_reset <= 1'b1;
        end else begin
            must_reset <= 1'b0;
        end

        if (flush == 1'b1) begin
            new_pc = main_branch_pc + 4;
        end
    end

    always @(posedge clk or posedge reset) begin
        if(reset == 1'b1) begin
            read_address <= 6'd0;
        end else if(read_enable == 1'b0) begin
            read_address <= 6'd0;
        end else begin
            if (read_address>>3 == (immediate[30:0])) begin
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

    uop_cache bram(.clk(clk), .reset(reset), .instruction(instruction), .read_enable(read_enable), .write_enable(write_enable), .read_address(read_address), .write_address(write_address), .out_instruction(out_instruction));

endmodule