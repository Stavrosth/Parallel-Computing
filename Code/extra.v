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
    input [31:0] curr_PC;
    input [31:0] instruction;
    input [31:0] immediate;
    input mispredict;

    output reg block_signal;
    output reg flush;
    output reg [31:0] new_pc;
    output [31:0] out_instruction; // From BRAM

    // Internal state registers
    reg [1:0] current_state;
    reg [31:0] main_branch_pc;
    reg must_reset;
    reg [5:0] write_address;
    reg [5:0] read_address;
    reg bram_read_enable_reg;   // Registered enable for BRAM read
    reg bram_write_enable_reg;  // Registered enable for BRAM write

    // Parameters
    parameter TRACK     = 2'b00, 
              BUFFERING = 2'b01, 
              REUSE     = 2'b10, 
              RESET     = 2'b11;

    parameter JAL_OPCODE   = 7'b1101111;
    parameter BTYPE_OPCODE = 7'b1100011;
    parameter LOOP_SIZE = -27;

    // Wires
    wire [6:0] opcode = instruction[6:0];
    wire last_bit_immediate = immediate[31];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state         <= TRACK;
            main_branch_pc        <= 32'd0;
            must_reset            <= 1'b0;
            block_signal          <= 1'b0;
            flush                 <= 1'b0;
            new_pc                <= 32'd0;
            write_address         <= 6'd0;
            read_address          <= 6'd0;
            bram_read_enable_reg  <= 1'b0;
            bram_write_enable_reg <= 1'b0;
        end else begin
            // Local variables for this cycle's combinational logic
            reg [1:0] next_state_calc;
            reg change_main_pc_calc;
            reg read_enable_decision;  // FSM's decision for read enable this cycle
            reg write_enable_decision; // FSM's decision for write enable this cycle
            reg block_signal_calc;
            reg flush_calc;
            wire goto_buffering_calc;

            goto_buffering_calc = ((opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) && 
                                   (last_bit_immediate == 1'b1) && 
                                   (immediate >= LOOP_SIZE));

            next_state_calc         = current_state;
            block_signal_calc       = 1'b0;
            flush_calc              = 1'b0;
            read_enable_decision    = 1'b0;
            write_enable_decision   = 1'b0;
            change_main_pc_calc     = 1'b0;

            case (current_state)
                TRACK: begin
                    if (goto_buffering_calc) begin
                        change_main_pc_calc = 1'b1;
                        next_state_calc     = BUFFERING;
                    end else begin
                        // change_main_pc_calc = 1'b0; // Default
                        next_state_calc     = TRACK;
                    end
                end
                BUFFERING: begin
                    change_main_pc_calc   = 1'b1;
                    write_enable_decision = 1'b1;
                    if (opcode == BTYPE_OPCODE || opcode == JAL_OPCODE) begin
                        if (must_reset) begin
                            next_state_calc = RESET;
                        end else begin
                            block_signal_calc = 1'b1;
                            next_state_calc   = REUSE;
                        end
                    end else begin
                        next_state_calc = BUFFERING;
                    end
                end
                REUSE: begin
                    change_main_pc_calc  = 1'b1;
                    block_signal_calc    = 1'b1;
                    read_enable_decision = 1'b1;
                    next_state_calc      = RESET; // Unconditional as per original logic
                end
                RESET: begin
                    flush_calc          = 1'b1;
                    // change_main_pc_calc = 1'b0; // Default
                    next_state_calc     = TRACK;
                end
                default: begin
                    // change_main_pc_calc = 1'b0; // Default
                    // flush_calc = 1'b0; // Default
                    next_state_calc     = TRACK;
                end
            endcase

            // Update registered outputs and internal FSM registers
            block_signal          <= block_signal_calc;
            flush                 <= flush_calc;
            bram_read_enable_reg  <= read_enable_decision;
            bram_write_enable_reg <= write_enable_decision;

            if (change_main_pc_calc == 1'b0) begin
                main_branch_pc <= curr_PC;
            end

            if (change_main_pc_calc == 1'b0) { 
                must_reset <= 1'b0;
            } else { 
                if (main_branch_pc != curr_PC) {
                    must_reset <= 1'b1;
                } else {
                    must_reset <= 1'b0;
                }
            }
            
            if (flush_calc == 1'b1) begin
                new_pc <= main_branch_pc + 32'd4;
            end

            // Update read_address based on FSM's read_enable_decision for this cycle
            if (read_enable_decision == 1'b0) begin
                read_address <= 6'd0;
            end else begin
                if ((read_address >> 3) == immediate[30:0]) begin 
                    read_address <= 6'd0;
                end else begin
                    read_address <= read_address + 6'd8;
                end
            end

            // Update write_address based on FSM's write_enable_decision for this cycle
            if (write_enable_decision == 1'b1) begin
                write_address <= write_address + 6'd8;
            end else begin
                write_address <= 6'd0;
            end

            current_state <= next_state_calc;
        end
    end

    // Instantiate the uop_cache (Block RAM)
    uop_cache bram(
        .clk(clk), 
        .reset(reset), 
        .instruction(instruction),      // Data in to BRAM
        .read_enable(bram_read_enable_reg), // Controlled by FSM
        .write_enable(bram_write_enable_reg),// Controlled by FSM
        .read_address(read_address),    // Read address to BRAM
        .write_address(write_address),  // Write address to BRAM
        .out_instruction(out_instruction) // Data out from BRAM
    );

endmodule