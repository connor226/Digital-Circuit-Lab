
`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

module SW_Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_READ_REF = 2'b00;
localparam S_READ_SR = 2'b01;
localparam S_WAIT = 2'b10;
localparam S_SEND = 2'b11;

logic in_ready_w, out_ready_w, out_valid, in_valid_w, avm_read_w, avm_write_w, core_rst, rst_w;
logic [1:0] state_w;
logic [2*`REF_MAX_LENGTH-1:0] ref_w;
logic [2*`READ_MAX_LENGTH-1:0] read_w;
logic [$clog2(`REF_MAX_LENGTH):0] bp_count_w;
logic signed [9:0] alignment_score;
logic [6:0] column;
logic [6:0] row;
logic [255:0] o_buffer_w;
logic [4:0] avm_address_w;

reg   in_ready_r, in_valid_r, avm_read_r, avm_write_r, rst_r;
reg   [1:0] state_r;
reg   [2*`REF_MAX_LENGTH-1:0] ref_r;
reg   [2*`READ_MAX_LENGTH-1:0] read_r;
reg   [$clog2(`REF_MAX_LENGTH):0] bp_count_r;
reg   [255:0] o_buffer_r;
reg   [4:0] avm_address_r;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = o_buffer_r[247-:8];
assign core_rst = avm_rst | rst_r;

// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(core_rst),

	.o_ready			(out_ready_w),
    .i_valid			(in_valid_r),
    .i_sequence_ref		(ref_r),
    .i_sequence_read	(read_r),
    .i_seq_ref_length	(8'd128),
    .i_seq_read_length	(8'd128),
    
    .i_ready			(in_ready_r),
    .o_valid			(out_valid),
    .o_alignment_score	(alignment_score),
    .o_column			(column),
    .o_row				(row)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

// TODO
always_comb begin
    state_w = state_r;
    ref_w = ref_r;
    read_w = read_r;
    in_ready_w = in_ready_r;
    in_valid_w = in_valid_r;
    bp_count_w = bp_count_r;
    o_buffer_w = o_buffer_r;
    rst_w = rst_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    avm_address_w = avm_address_r;
    case(state_r)
        S_READ_REF: begin
            if(!avm_waitrequest)  begin
                if(avm_address_r == STATUS_BASE & avm_readdata[RX_OK_BIT]) begin
                    StartRead(RX_BASE);
                end
                else if(avm_address_r == RX_BASE) begin
                    ref_w = ref_w << 8;
                    ref_w[7:0] = avm_readdata[7:0];
                    bp_count_w = bp_count_w + 1'b1;
                    StartRead(STATUS_BASE);
                    if(bp_count_w[5]) begin
                        state_w = S_READ_SR;
                        bp_count_w = 0;
                    end
                end
            end
        end
        S_READ_SR: begin
            if(!avm_waitrequest)  begin
                if(avm_address_r == STATUS_BASE & avm_readdata[RX_OK_BIT]) begin
                    StartRead(RX_BASE);
                end
                else if(avm_address_r == RX_BASE) begin
                    read_w = read_w << 8;
                    read_w[7:0] = avm_readdata[7:0];
                    bp_count_w = bp_count_w + 1'b1;
                    StartRead(STATUS_BASE);
                    if(bp_count_w[5]) begin
                        state_w = S_WAIT;
                        bp_count_w = 0;
                        rst_w = 1;
                    end
                end
            end
        end
        S_WAIT: begin
            rst_w = 0;
            in_ready_w = 1'b1;
            in_valid_w = 1'b1;
            if(out_valid) begin
                in_ready_w = 1'b0;
                in_valid_w = 1'b0;
                o_buffer_w[9:0] = alignment_score;
                o_buffer_w[70:64] = row;
                o_buffer_w[134:128] = column;
                state_w = S_SEND;
            end
        end
        S_SEND: begin
            if(!avm_waitrequest) begin
                if(avm_address_r == STATUS_BASE & avm_readdata[TX_OK_BIT]) begin
                    StartWrite(TX_BASE);
                end
                else if(avm_address_r == TX_BASE) begin
                    o_buffer_w = o_buffer_w << 8;
                    bp_count_w = bp_count_w + 1;
                    StartRead(STATUS_BASE);
                    if(&bp_count_w[4:0]) begin
                        state_w = S_READ_REF;
                        bp_count_w = 0;
                        StartRead(STATUS_BASE);
                    end
                end
            end
        end
    endcase
end

// TODO
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        state_r <= S_READ_REF;
        ref_r <= 0;
        read_r <= 0;
        in_ready_r <= 1'b0;
        in_valid_r <= 1'b0;
        bp_count_r <= 0;
        o_buffer_r <= 0;
        rst_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
    end
	else begin
    	state_r <= state_w;
        ref_r <= ref_w;
        read_r <= read_w;
        in_ready_r <= in_ready_w;
        in_valid_r <= in_valid_w;
        bp_count_r <= bp_count_w;
        o_buffer_r <= o_buffer_w;
        rst_r <= rst_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
    end
end

endmodule
