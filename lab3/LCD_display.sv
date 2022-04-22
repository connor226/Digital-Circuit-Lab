module LCD(
    input  i_clk,
    input  i_mode,
    output [7:0] o_LCD_DATA,
	 output o_LCD_EN,
	 output o_LCD_RS,
	 output o_LCD_RW,
	 output o_LCD_ON,
	 output o_LCD_BLON
);

// ascii value table for displayed characters
localparam ascii_C = 8'h43;
localparam ascii_u = 8'h75;
localparam ascii_r = 8'h72;
localparam ascii_e = 8'h65;
localparam ascii_n = 8'h6e;
localparam ascii_t = 8'h74;
localparam ascii_m = 8'h6d;
localparam ascii_o = 8'h6f;
localparam ascii_d = 8'h64;
localparam colon   = 8'h3a;
localparam ascii_R = 8'h52;
localparam ascii_c = 8'h63;
localparam ascii_P = 8'h50;
localparam ascii_l = 8'h6c;
localparam ascii_a = 8'h61;
localparam ascii_y = 8'h79;
localparam space   = 8'h20;

// operation types
localparam idle   = 8'bzzzz_zzzz;
localparam clear  = 8'b0000_0001;
localparam cursor = 8'b0000_0010;
localparam inputm = 8'b0000_0110;
localparam switch = 8'b0000_1111;
localparam shift  = 8'b0001_1100;
localparam setfun = 8'b0011_1100;
localparam setadd = 8'b1000_0000;

// states
localparam S_IDLE   = 4'd0;
localparam S_CLEAR  = 4'd1;
localparam S_CURSOR = 4'd2;
localparam S_INPUT  = 4'd3;
localparam S_SWITCH = 4'd4;
localparam S_SHIFT  = 4'd5;
localparam S_SETFUN = 4'd6;
localparam S_SADDR1 = 4'd7;
localparam S_WRITE1 = 4'd8;
localparam S_SADDR2 = 4'd9;
localparam S_WRITE2 = 4'd10;

// regs
reg rw, rs;
reg [3:0] state_r;
reg [7:0] data;
reg [7:0] addr = 8'b1000_0000;

assign o_LCD_ON = 1'b1;
assign o_LCD_EN = i_clk;
assign o_LCD_RW = rw;
assign o_LCD_RS = rs;
assign o_LCD_DATA = data;
assign o_LCD_BLON = 1'b1;

function [7:0] char;
	input [7:0] addr;
	begin
		case(addr)
			8'h81: char = ascii_C;
			8'h82: char = ascii_u;
			8'h83: char = ascii_r;
			8'h84: char = ascii_r;
			8'h85: char = ascii_e;
			8'h86: char = ascii_n;
			8'h87: char = ascii_t;
			8'h89: char = ascii_m;
			8'h8a: char = ascii_o;
			8'h8b: char = ascii_d;
			8'h8c: char = ascii_e;
			8'h8d: char = colon;
			8'hc9: char = (i_mode ? ascii_R : space);
			8'hca: char = (i_mode ? ascii_e : space);
			8'hcb: char = (i_mode ? ascii_c : ascii_P);
			8'hcc: char = (i_mode ? ascii_o : ascii_l);
			8'hcd: char = (i_mode ? ascii_r : ascii_a);
			8'hce: char = (i_mode ? ascii_d : ascii_y);
			default: char = space;
		endcase
	end
endfunction

always_ff @(posedge i_clk) begin
	case(state_r)
		S_IDLE: begin
			state_r <= S_CLEAR;
			rw <= rw;
			rs <= rs;
			data <= idle;
		end
		S_CLEAR: begin
			state_r <= S_INPUT;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= clear;
		end
		S_INPUT: begin
			state_r <= S_SWITCH;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= inputm;
		end
		S_SWITCH: begin
			state_r <= S_SHIFT;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= switch;
		end
		S_SHIFT: begin
			state_r <= S_SETFUN;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= shift;
		end
		S_SETFUN: begin
			state_r <= S_SADDR1;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= setfun;
		end
		S_SADDR1: begin
			state_r <= S_WRITE1;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= addr;
		end
		S_WRITE1: begin
			data <= char(addr);
			rw <= 1'b0;
			rs <= 1'b1;
			if(&addr[3:0]) begin
				state_r <= S_SADDR2;
				addr <= 8'b1100_0000;
			end
			else begin
				state_r <= S_SADDR1;
				addr <= addr + 1'b1;
			end
		end
		S_SADDR2: begin
			state_r <= S_WRITE2;
			rw <= 1'b0;
			rs <= 1'b0;
			data <= addr;
		end
		S_WRITE2: begin
			data <= char(addr);
			rw <= 1'b0;
			rs <= 1'b1;
			if(&addr[3:0]) begin
				state_r <= S_SADDR1;
				addr <= 8'b1000_0000;
			end
			else begin
				state_r <= S_SADDR2;
				addr <= addr + 1'b1;
			end
		end
		default: begin
			state_r <= state_r;
			data <= data;
			rw <= rw;
			rs <= rs;
		end
	endcase
end

endmodule
