module Top(
    // general
    input i_rst_n,
	input i_clk,
    input i_mode, // mode 0: register, mode 1: compare
    input i_baud, // 115200 Hz

    // SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,

    // FLASH
    output [22:0] o_FL_ADDR,
	output o_FL_CE_N,
	inout [7:0] io_FL_DQ,
	output o_FL_OE_N,
	output o_FL_RST_N,
	input i_FL_RY,
	output o_FL_WE_N,
	output o_FL_WP_N,
    
);
localparam S_IDLE = 3'b000;
localparam S_SAVE1 = 3'b001;
localparam S_SAVE2 = 3'b010;
localparam S_SAVE3 = 3'b011;
localparam S_COMPARE = 3'b100;
localparam S_READ = 3'b101;
localparam S_ADCONVERT = 3'b110;


assign o_SRAM_WE_N = (state_r == S_READ) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign o_FL_WE_N = (state_r == S_SAVE1 || state_r == S_SAVE2 || state_r == SAVE3) ? 1'b0: 1'b1;
assign o_FL_CE_N = 1'b0;
assign o_FL_OE_N = 1'b0;
assign o_FL_WP_N = 1'b0;
assign o_FL_RST_N = 1'b1;

logic [2:0] state_w, state_r;

always_comb begin
    state_w = state_r;
    case(state_r)
        S_IDLE: begin // wait for new fingerprint input
        end
        S_READ: begin // read analog fingerprint from sensor and store in SRAM
        end
        S_ADCONVERT: begin // convert analog fingerprint to digital value
        end
        S_SAVE1: begin // register mode: save 1st fingerprint to flash
        end
        S_SAVE2: begin // register mode: save 2nd fingerprint to flash
        end
        S_SAVE3: begin // register mode: save 3rd fingerprint to flash
        end
        S_COMPARE: begin // compare mode: output whether the input fingerprint is in database
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state_r <= S_IDLE;
    end
    else begin
        state_r <= state_w;
    end
end

endmodule