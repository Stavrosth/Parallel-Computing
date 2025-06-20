`ifndef TESTBENCH
`include "constants.vh"
`include "config.vh"
`else
`include "../includes/constants.vh"
`include "../includes/config.vh"
`endif


module memory(input clk,
            input [`TEXT_BITS-3:0] PC,
            input reset,
            output reg [31:0] instr,
            input [`DATA_BITS-3:0] data_addr,
            input ren, wen,
            input [31:0] data_in,
            output reg [31:0] data_out,
            input [3:0] byte_select_vector,
            output reg ready
);

localparam data_size=1024;

(* ram_style = "block" *) reg [31:0] data_mem [0:data_size-1]; // Forces BRAM inference

// Initialize memory with instructions
initial begin
    data_mem[0]  = 32'h04100513;
    data_mem[1]  = 32'h00150513;
    data_mem[2]  = 32'h880004b7;
    data_mem[3]  = 32'h04048913;
    data_mem[4]  = 32'h00000293;
    data_mem[5]  = 32'h02000313;
    data_mem[6]  = 32'h00000393;
    data_mem[7]  = 32'h00400e13;
    data_mem[8]  = 32'h00548f33;
    data_mem[9]  = 32'h00af1023;
    data_mem[10] = 32'h00228293;
    data_mem[11] = 32'hfe62cae3;
    data_mem[12] = 32'h020f0f13;
    data_mem[13] = 32'h00af1023;
    data_mem[14] = 32'h00138393;
    data_mem[15] = 32'hffc3cae3;
    data_mem[16] = 32'h00f00293;
    data_mem[17] = 32'hfe0f0f13;
    data_mem[18] = 32'hffef0f13;
    data_mem[19] = 32'h00af1023;
    data_mem[20] = 32'hfff28293;
    // data_mem[21] = 32'hfe029ae3;
    data_mem[21] = 32'h00000393;
    data_mem[22] = 32'hfe0f0f13;
    data_mem[23] = 32'h00af1023;
    data_mem[24] = 32'h00138393;
    data_mem[25] = 32'hffc3cae3;
    data_mem[26] = 32'hf9dff06f;
    data_mem[27] = 32'h0000006f;
    // data_mem[29] = 32'h00541023;
    // data_mem[30] = 32'h00240413;
    // data_mem[31] = 32'h0000006f;
end

localparam STATE_IDLE = 2'b00;
localparam STATE_READING = 2'b01;
localparam STATE_WRITING = 2'b10;
localparam STATE_FINISHED = 2'b11;
reg [1:0] state = 0;
reg [4:0] cnt = 0;
reg [`DATA_BITS-1:0] saved_data_addr = 0;
always@(posedge clk)
begin 

    if(PC < data_size)
    begin
        instr <= data_mem[PC];
    end
    ready <= 1;
    case(state)
    STATE_IDLE:
    begin
    if(data_addr < data_size)
    begin
        cnt <= 0;
        saved_data_addr <= data_addr;
        if(wen == 1'b1 && ren==1'b1)
            begin
                data_out <= data_in;
            end
            else if (wen == 1'b1 && ren==1'b0) begin
                if (byte_select_vector[3] == 1'b1)
                    data_mem[data_addr][31:24] <= data_in[31:24];
                if (byte_select_vector[2] == 1'b1)
                    data_mem[data_addr][23:16] <= data_in[23:16];
                if (byte_select_vector[1] == 1'b1)
                    data_mem[data_addr][15:8] <= data_in[15:8];
                if (byte_select_vector[0] == 1'b1)
                    data_mem[data_addr][7:0] <= data_in[7:0];
            end
            else if (ren == 1'b1 && wen==1'b0)
            begin
                ready<=0;
                state <= STATE_READING;
            end
            else
                data_out <= 32'b0;
        end
        else
        begin
            data_out <= 32'b0;
        end
    end
    STATE_READING:
    begin
        cnt <= cnt + 1;
        if(cnt > 5'd5)
        begin
            ready <= 1;
            state <= STATE_IDLE;
            data_out <= data_mem[saved_data_addr];
        end
        else
        begin
            ready <= 0;
            state <= STATE_READING;
        end
    end
    STATE_WRITING:
    begin

    end
    STATE_FINISHED:
    begin
        
    end

    endcase

       
end


endmodule

/* SIMPLE FSM SIMPLE LOOP TESETBENCH
04100513: addi a0, zero, 65 
00150513: addi a0, a0, 1 
880004b7: lui s1, -2013265920 
04048913: addi s2, s1, 64 
00000293: addi t0, zero, 0 
02000313: addi t1, zero, 32 
00000393: addi t2, zero, 0 
00400e13: addi t3, zero, 4 
00548f33: add t5, s1, t0 
00af1023: sh a0, 0(t5) 
00228293: addi t0, t0, 2 
fe62cae3: blt t0, t1, -12 
020f0f13: addi t5, t5, 32 
00af1023: sh a0, 0(t5) 
00138393: addi t2, t2, 1 
ffc3cae3: blt t2, t3, -12 
00f00293: addi t0, zero, 15 
fe0f0f13: addi t5, t5, -32 
ffef0f13: addi t5, t5, -2 
00af1023: sh a0, 0(t5) 
fff28293: addi t0, t0, -1 
00000393: addi t2, zero, 0 
fe0f0f13: addi t5, t5, -32 
00af1023: sh a0, 0(t5) 
00138393: addi t2, t2, 1 
ffc3cae3: blt t2, t3, -12 
f9dff06f: jal zero, -100 
0000006f: jal zero, 0 
*/