module simpleFSM(
    clk,
    reset,
    curr_PC,
    instruction, 
    bubble_idex,
    immediate,
    block_signal,
    mispredict,
    flush,
    new_pc,
    out_instruction
    );
    
    /***** INPUTS & OUTPUTS******/
    input clk, reset, mispredict,bubble_idex;
    input [31:0] immediate, instruction, curr_PC;
    output reg block_signal, flush;
    output reg [31:0] new_pc;

    /***** FSM VARIABLES ******/
    reg [2:0] current_state, next_state;
    reg [31:0] main_branch_pc; // Program Counter of the branch
    reg change_main_pc; // Allows the FSM to change the main branch pc
    reg [31:0] reg_immediate; // Was added because the synthesis was not working
    reg [31:0] pc_to_store; // Stores Temporarily the PC of the branch to store in the next cycle in main_branch_pc
    reg [31:0] branch_immediate; // Used to calculate the read address of the bram during reuse
    reg [6:0] opcode; // Was added because the synthesis was not working
    reg mispredict_signal; // Was added because the synthesis was not working
    reg must_reset; // Was added because the synthesis was not working (for the FSM to return to RESET state)
    reg goto_buffering; // Detects a branch
    reg change_address; // Allows the bram to change address
    wire change_address_first; // Allows Bram to change address one cycle earlier in order to store the first instruction
    parameter signed [31:0] LOOP_SIZE = -27; // MMAXIMUM LOOP SIZE accepted 

    parameter TRACK = 3'b000,    // State encoding for the FSM
              BUFFERING = 3'b001,
              WAIT = 3'b010, 
              REUSE = 3'b011;

    parameter JAL_OPCODE =  7'b1101111, // remove this when implemented to RISC V 
              BTYPE_OPCODE = 7'b1100011; // then we will get the opcode from the include file
              
    /***** BRAM VARIABLES ******/    
    output [31:0] out_instruction;
    reg [5:0] write_address, read_address;
    reg read_enable, write_enable;

    // FSM sequential block
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= TRACK;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM combinational block
    always @(*) begin
        next_state = current_state;
        block_signal = 1'b0;
        flush = 1'b0;
        read_enable = 1'b0;
        write_enable = 1'b0;
        change_main_pc = 1'b0;
        change_address = 1'b0;
        
        case (current_state)
            TRACK: begin
                write_enable = 1'b1;

               if(goto_buffering) begin // Detects a branch
                    change_address = 1'b1;
                    next_state = BUFFERING;
                end else begin
                    change_main_pc = 1'b1;
                    next_state = TRACK;
                end
            end
            BUFFERING: begin
                if(opcode== BTYPE_OPCODE || opcode == JAL_OPCODE) begin //check that loop is a basic block
                    if (must_reset) begin // make sure the branch is not the one of our loop
                        next_state = TRACK;
                    end
                    else begin
                        next_state = WAIT;
                    end
                end
                else begin
                    change_address = 1'b1;
                    write_enable = 1'b1;
                    next_state = BUFFERING;
                end
            end
            WAIT: begin // Waits for BRAM to read
                block_signal = 1'b1;
                read_enable = 1'b1;
                next_state = REUSE;
            end
            REUSE: begin
                if(mispredict_signal == 1'b1) begin
                    flush = 1'b1;
                    next_state = TRACK;
                end else begin
                    block_signal = 1'b1;
                    read_enable = 1'b1;
                    next_state = REUSE;
                end
            end
            default: begin 
                next_state = current_state;
                block_signal = 1'b0;
                flush = 1'b0;
                read_enable = 1'b0;
                write_enable = 1'b0;
                change_main_pc = 1'b0;
                change_address = 1'b0;
            end
        endcase

    end

    // Was added because the synthesis was not working
    always@(posedge clk or negedge reset) begin
        if(!reset) begin
            opcode <= 7'b0;
            reg_immediate <= 32'b0;
            mispredict_signal <= 1'b0;
        end else begin
            opcode <= instruction[6:0];
            reg_immediate <= immediate;
            mispredict_signal <= mispredict;
        end
    end
    
    // Always block that manages the pc_to_store, goto_buffering and branch_immediate
    always@(posedge clk or negedge reset) begin   
        if(!reset) begin
            pc_to_store <= 32'd0;
            goto_buffering<=1'b0;
            branch_immediate <= 32'd0;
        end else if(((opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) && (reg_immediate[31] == 1'b1) && (reg_immediate >= LOOP_SIZE))) begin
            pc_to_store <= 32'd0;
            goto_buffering<=1'b1;
            branch_immediate<= reg_immediate;
        end else begin
            pc_to_store <= curr_PC;
            goto_buffering<=1'b0;
        end
    end

    //Always block that manages the main branch pc and new pc
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            main_branch_pc <= 32'd0;
            new_pc <= 32'd0;
        end else if(change_main_pc == 1'b1) begin
            main_branch_pc <= pc_to_store;
        end else if (flush == 1'b0) begin
            new_pc <= main_branch_pc + 4;
        end
    end

    //Always block that manages the must_reset signal
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            must_reset <= 1'b0;
        end else if (main_branch_pc == curr_PC) begin
            must_reset <= 1'b0;
        end else if (main_branch_pc != curr_PC) begin
            must_reset <= 1'b1;
        end
    end

    //Always block that manages read signals for bram
    always @(posedge clk or negedge reset) begin
        if(!reset == 1'b1) begin
            read_address <= 6'h20;
        end else if(read_enable == 1'b0) begin
            read_address <= 6'h20;
        end else begin
            if ((read_address>>3) >= (~branch_immediate +1)+4) begin
                read_address <= 6'h20;
            end else if(~bubble_idex) begin
                read_address <= read_address + 6'd8;
            end
        end
    end

    //Always block that manages write signals for bram
    always @(posedge clk or negedge reset) begin
        if(!reset == 1'b1) begin
            write_address <= 6'd0;
        end else if((write_enable == 1'b1 && change_address == 1'b1) || change_address_first == 1'b1) begin
            write_address <= write_address + 6'd8;
        end else begin
            write_address <= 6'd0;
        end
    end

    // Used to Allow the BRAM to write the first instruction of the loop
    assign change_address_first = ((opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) && (reg_immediate[31] == 1'b1) && (reg_immediate >= LOOP_SIZE)) ? 1'b1 : 1'b0;

    uop_cache bram(.clk(clk), .reset(!reset), .instruction(instruction), .read_enable(read_enable), .write_enable(write_enable), .read_address(read_address), .write_address(write_address), .out_instruction(out_instruction));

endmodule
