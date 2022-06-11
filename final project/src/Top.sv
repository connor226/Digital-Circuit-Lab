module Top(
	// general
	input i_rst_n,
	input i_clk,
	input i_mode, // mode 0: register, mode 1: compare
	input i_baud, // 115200 Hz
	input i_start,
	input i_rx_from_sfm, // GPIO[26]
	output o_tx_to_sfm,  // GPIO[27]

    // SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// seven hex decoder
	output [7:0] o_shd0,
	output [7:0] o_shd1,
		
   // debug
	output [7:0] o_debug0,
	output [1:0] o_debug1,
	output [17:0] o_debug2,
	output [2:0] o_debug3
);
localparam S_IDLE = 3'b000;
localparam S_SAVE1 = 3'b001;
localparam S_SAVE2 = 3'b010;
localparam S_SAVE3 = 3'b011;
localparam S_COMPARE = 3'b100;
localparam S_HOLD = 3'b101;
localparam S_ADCONVERT = 3'b110;
localparam S_READ = 3'b111;

localparam SRAM_BEGIN_ADDRESS = 20'd0;
localparam DB_SIZE_ADDRESS = 20'd12999;
localparam SAVE_BEGIN_ADDRESS = 20'd13000;
localparam FP_SIZE = 20'd1600;

logic write_to_sram, fpr_start, fpr_finished, adc_start, adc_finished;
logic [1:0] adc_output, save_cnt_w = 2'b01, save_cnt_r = 2'b01;
logic [2:0] state_w, state_r;
logic [3:0] match_result_w, match_result_r;
logic [7:0] avg1, avg2, avg3, avg4, row_w, column_w;
logic [15:0] fpr_sram_data, working_data, db_size_w, db_size_r;
logic [19:0] fpr_sram_addr, adc_sram_addr, working_addr_w, working_addr_r;
logic [1:0] same_fp_cnt_w, same_fp_cnt_r ;
logic [3:0] fp_cnt_w, fp_cnt_r ;

logic [25:0] timer_r;
logic [159:0][159:0] fp_d_w ;
logic [159:0][159:0] fp_d_r ;

//core logic
logic core_start, core_finish ;
logic [19:0] core_fp_address, core_sram_address ;
logic [15:0] high_score_w, high_score_r, core_match ;
logic [3:0]  best_fp_w, best_fp_r ;

// debug locic
logic [7:0] cnt_w;
logic [1:0] fpr_state;
logic [14:0] byte_counter;
logic [7:0] row_cnt_w, row_cnt_r, column_cnt_w, column_cnt_r;

assign o_SRAM_WE_N = (state_r == S_SAVE1 || state_r == S_SAVE2 || state_r == S_SAVE3 || state_r == S_READ) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;
assign io_SRAM_DQ = (state_r == S_SAVE1 || state_r == S_SAVE2 || state_r == S_SAVE3 || state_r == S_READ) ? (&state_r ? fpr_sram_data : working_data) : 16'dz;
assign o_SRAM_ADDR = state_r == S_IDLE ? DB_SIZE_ADDRESS : (!state_r[2] ? working_addr_r : (&state_r ? fpr_sram_addr : (state_r[1]? adc_sram_addr:core_sram_address)));

assign o_shd0 = {match_result_r, db_size_r[3:0]};
assign o_shd1 = {save_cnt_r, 2'b00, same_fp_cnt_r};

// debug assign
assign o_debug0 = cnt_w;
assign o_debug1 = fpr_state;
assign o_debug2 = o_SRAM_ADDR[17:0];
assign o_debug3 = state_r;

FP_Reader FP1(
	.i_clk(i_clk),
	.i_rst(!i_rst_n),
	.i_start(fpr_start),
	.i_baud(i_baud),
	.i_rx_from_sfm(i_rx_from_sfm),
	.i_begin_addr(SRAM_BEGIN_ADDRESS),      // begin with this SRAM address
	.o_sram_data(fpr_sram_data),            // data from SRAM
	.o_sram_addr(fpr_sram_addr),
	.o_write(write_to_sram),                // write data
	.o_finish(fpr_finished),
	.o_avg1(avg1),
	.o_avg2(avg2),
	.o_avg3(avg3),
	.o_avg4(avg4),
	.o_tx_to_sfm(o_tx_to_sfm),

	// debug output
	.o_state(fpr_state),
	.o_tmp(byte_counter),
	.o_cnt(cnt_w)
);

ADconvert ADC(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_start(adc_start),
	.threshold1(avg1),
	.threshold2(avg2),
	.threshold3(avg3),
	.threshold4(avg4),
	.data(io_SRAM_DQ),
	.i_begin_addr(SRAM_BEGIN_ADDRESS),
	.o_row(row_w),
	.o_column(column_w),
	.o_finished(adc_finished),
	.o_sram_addr(adc_sram_addr),
	.o_data(adc_output)
);

Core C1(
    .i_clk(i_clk),
    .i_start(core_start),
    .i_sram_data(io_SRAM_DQ),
    .i_begin_address(core_fp_address),
    .i_full_fp(fp_d_r),
    .o_sram_address(core_sram_address),
    .o_match(core_match),
    .o_finish(core_finish)
);

always_comb begin
	state_w = state_r;
	save_cnt_w = save_cnt_r;
	db_size_w = db_size_r;
	fpr_start = 1'b0;
	adc_start = 1'b0;
	row_cnt_w = row_cnt_r;
	column_cnt_w = column_cnt_r;
	working_addr_w = working_addr_r;
	working_data = 16'd0 ;
	fp_d_w = fp_d_r ;
	// core
	same_fp_cnt_w = same_fp_cnt_r ;
	fp_cnt_w = fp_cnt_r ;
	core_start = 0 ;
	core_fp_address = 0 ;
	match_result_w = match_result_r;
	high_score_w = high_score_r ;
	best_fp_w = best_fp_r ;
	
	case(state_r)
		S_IDLE: begin // wait for new fingerprint input
			db_size_w = io_SRAM_DQ;
			if(i_start) begin
				state_w = S_READ;
				match_result_w = 0;
			end
		end
		S_READ: begin // read analog fingerprint from sensor and store in SRAM
			fpr_start = 1'b1;
			if(fpr_finished || &timer_r) begin
				state_w = S_ADCONVERT;
			end
		end
		S_ADCONVERT: begin // convert analog fingerprint to digital value
			adc_start = row_w ? 1'b0 : 1'b1;
			fp_d_w[row_w][column_w] = adc_output[0];
			fp_d_w[row_w][column_w+1] = adc_output[1];
			if(adc_finished) begin
				state_w = i_mode ? S_COMPARE : {1'b0, save_cnt_r};
				row_cnt_w = 0;
				column_cnt_w = 0;
				same_fp_cnt_w = 0;
				fp_cnt_w = 0;
				working_addr_w = SAVE_BEGIN_ADDRESS + FP_SIZE * (db_size_r * 3 + save_cnt_r - 1);  //the address for this new fingerprint
				high_score_w = 0 ;
				best_fp_w = 0 ;
			end
		end
		S_SAVE1: begin // register mode: save 1st fingerprint to flash
			working_data = fp_d_r[row_cnt_r][(column_cnt_r+15)-:16]; 
			column_cnt_w = column_cnt_r + 16;
			working_addr_w = working_addr_r + 1;
			if(column_cnt_w == 8'd160) begin
				column_cnt_w = 8'd0;
				row_cnt_w = row_cnt_r + 1;
			end
			if(row_cnt_w == 8'd160) begin
				state_w = S_IDLE;  // go to S_IDLE
				save_cnt_w = save_cnt_r + 1;
			end
		end
		S_SAVE2: begin // register mode: save 2nd fingerprint to flash
			working_data = fp_d_r[row_cnt_r][(column_cnt_r+15)-:16]; 
			column_cnt_w = column_cnt_r + 16;
			working_addr_w = working_addr_r + 1;
			if(column_cnt_w == 8'd160) begin
				column_cnt_w = 8'd0;
				row_cnt_w = row_cnt_r + 1;
			end
			if(row_cnt_w == 8'd160) begin
				state_w = S_IDLE;  // go to S_IDLE
				save_cnt_w = save_cnt_r + 1;
			end
		end
		S_SAVE3: begin // register mode: save 3rd fingerprint to flash
			if(row_cnt_w < 8'd160) begin
				working_data = fp_d_r[row_cnt_r][(column_cnt_r+15)-:16]; 
				column_cnt_w = column_cnt_r + 16;
				working_addr_w = working_addr_r + 1;
				if(column_cnt_w == 8'd160) begin
					column_cnt_w = 8'd0;
					row_cnt_w = row_cnt_r + 1;
				end
			end
			else begin
				save_cnt_w = 2'b01;
					working_addr_w = DB_SIZE_ADDRESS; // change the size of db
					working_data = db_size_r + 1;
			end
			if(working_addr_r == DB_SIZE_ADDRESS) begin
				working_data = db_size_r + 1;
				state_w = S_IDLE;
			end
		end
		S_COMPARE: begin // compare mode: output whether the input fingerprint is in database
				if(same_fp_cnt_r<3) begin
					core_start = 1 ;
					core_fp_address = SAVE_BEGIN_ADDRESS + FP_SIZE * fp_cnt_r * 3 + FP_SIZE * same_fp_cnt_r ;
					same_fp_cnt_w = same_fp_cnt_r + 1 ;
					state_w = S_HOLD ;
					deb_fin_w = 0 ;
				end
				else begin	// next fp
					same_fp_cnt_w = 0 ;
					if(fp_cnt_r < db_size_r-1) begin	// next different fp
						fp_cnt_w = fp_cnt_r + 1 ;
					end
					else begin				// no match fp
						// TODO : 
						same_fp_cnt_w = 0 ;
						match_result_w = high_score_r > 1800 ? best_fp_r : 4'b0000; ;
						//
						state_w = S_IDLE ;
					end
				end
		end
		S_HOLD : begin
			core_start = 0  ;
			if(core_finish) begin	// matched -> return to IDLE
				if(core_match > high_score_r) begin
					high_score_w = core_match ;
					best_fp_w = fp_cnt_r+1 ;
					// match_result_w = fp_cnt_r + 1 ;
				end
				state_w = S_COMPARE ;
			end
		end
		default: begin
			state_w = S_IDLE;
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state_r <= S_IDLE;
		save_cnt_r <= 2'b01;
		timer_r <= 26'd0;
		row_cnt_r <= 0;
		column_cnt_r <= 0;
		working_addr_r <= SRAM_BEGIN_ADDRESS;
		same_fp_cnt_r <= 0 ;
		fp_cnt_r <= 0 ;
		match_result_r <= 0;
		high_score_r <= 0 ;
		best_fp_r <= 0 ;
	end
	else begin
		state_r <= state_w;
		save_cnt_r <= save_cnt_w;
		db_size_r <= db_size_w;
		timer_r <= &state_w ? timer_r + 1 : 26'd0;
		row_cnt_r <= row_cnt_w;
		column_cnt_r <= column_cnt_w;
		working_addr_r <= working_addr_w;
		fp_d_r <= fp_d_w;
		same_fp_cnt_r <= same_fp_cnt_w ;
		fp_cnt_r <= fp_cnt_w ;
		match_result_r <= match_result_w;
		high_score_r <= high_score_w ;
		best_fp_r <= best_fp_w ;
	end
end

endmodule