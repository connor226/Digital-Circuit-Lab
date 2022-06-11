module FP_Reader (
    input i_clk,
	 input i_rst,
    input i_start,
    input i_baud,
    input i_rx_from_sfm,
    input [19:0] i_begin_addr,      // begin with this SRAM address
    output [15:0] o_sram_data,      // data from SRAM
    output [19:0] o_sram_addr,
    output o_write,                 // write data
    output o_finish,
    output [7:0] o_avg1,
    output [7:0] o_avg2,
    output [7:0] o_avg3,
    output [7:0] o_avg4,
    output o_tx_to_sfm,
	 output [1:0] o_state,
	 output[14:0] o_tmp,
	 output [7:0] o_cnt
	 //output [3:0] o_seven_hex0,
	 //output [3:0] o_seven_hex1
);

localparam IDLE = 0 ;
localparam SEND = 1 ;
localparam READ1 = 2 ;
localparam READ2 = 3 ;
localparam START_CNT = 9 ;
localparam FINIS_CNT = 15'd25608 ; // 8+25600

logic [1:0] state_w, state_r ;
logic [14:0] byte_cnt_w, byte_cnt_r ; // about 25600 bytes
logic [15:0] data_w, data_r ;
logic [19:0] address_w, address_r ;
logic write_w, write_r, finish_w, finish_r ;
logic tx_data_w, tx_data_r ;
logic [15:0] debug_w,debug_r;

logic [7:0] sfm_data_w ;
logic sfm_finish_w,sfm_finish_r ;

logic get_rst_w, get_rst_r, get_start_w, get_start_r, get_fin_w ;


// wire & reg for average calculation
logic [18:0] sum1_w,sum2_w,sum3_w,sum4_w ;  // sum of grids : max value is 255*40*40(all white)
logic [18:0] sum1_r,sum2_r,sum3_r,sum4_r ;  // left-up : 1, right-up : 2, left-bottom : 3, right-bottom : 4
wire [7:0] i,j ;    // current position , define the upper left gird = (0,0)

assign o_sram_data = data_w ;			// FOR DEBUG
assign o_sram_addr = address_w ;
assign o_write = write_w ;
assign o_finish = finish_w ;
assign i = (byte_cnt_r-9)/160 ;
assign j = (byte_cnt_r-9)%160 ;
assign o_avg1 = sum1_w/1600 ;
assign o_avg2 = sum2_w/1600 ;
assign o_avg3 = sum3_w/1600 ;
assign o_avg4 = sum4_w/1600 ;
assign o_tmp = byte_cnt_r;

//assign o_seven_hex0 = o_avg1[7:4] ;//debug_r[3:0];
//assign o_seven_hex1 = o_avg1[3:0] ;//debug_r[7:4];
assign o_cnt = debug_r;

//wire tmp_w ;

assign o_state = state_r ;
//assign o_tmp = byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT ;


SFM_reader R1(
    .i_clk(i_baud),
    .i_rx_from_sfm(i_rx_from_sfm),
    .o_data(sfm_data_w),
    .o_finish(sfm_finish_w)

);

getImage G1(
    .i_clk(i_baud),
    .i_start(get_start_w),
    .i_rst(get_rst_r),
    .o_tx_to_sfm(o_tx_to_sfm),
    .o_finish(get_fin_w)
);

task add_to_sum;
    // this task adds the grid value(0~255) to one of the sum
    if(i>=40 && i<80) begin
        if(j>=40 && j<80)
            sum1_w = sum1_r + sfm_data_w ;  // left-up
        else if(j>=80 && j<120)
            sum2_w = sum2_r + sfm_data_w ;  // right-up
    end
    else if(i>=80 && i<120) begin
        if(j>=40 && j<80)
            sum3_w = sum3_r + sfm_data_w ;  // left-bottom
        else if(j>=80 && j<120)
            sum4_w = sum4_r + sfm_data_w ;  // right-bottom
    end
endtask


always_comb begin
    state_w = state_r ;
    byte_cnt_w = byte_cnt_r ;
    data_w = data_r ;
    finish_w = finish_r ;
    address_w = address_r ;
    write_w = write_r ;
    sum1_w = sum1_r ; 
	 sum2_w = sum2_r ; 
	 sum3_w = sum3_r ; 
	 sum4_w = sum4_r ; 
    get_rst_w = get_rst_r ;
    get_start_w = get_start_r ; 
	 debug_w = debug_r;

    case (state_r)
        IDLE : begin
            get_rst_w = 0 ;
            if(i_start) begin
                state_w = SEND ;
                byte_cnt_w = 0 ;
                data_w = 0 ;
                address_w = i_begin_addr - 1 ;
                write_w = 0 ;
                finish_w = 0 ;
                sum1_w = 0 ; 
					 sum2_w = 0 ; 
					 sum3_w = 0 ; 
					 sum4_w = 0 ; 
                get_start_w = 1 ; 
            end
        end 
        SEND : begin
            get_start_w = 0 ;
            if(get_fin_w) begin
                state_w = READ1 ;
                get_rst_w = 1 ;
            end
        end
        READ1 : begin
            write_w = 0 ;
				get_rst_w = 0;
            if(sfm_finish_w) begin // rising edge of finish from sfm reader
					byte_cnt_w = byte_cnt_r + 1 ;
                if(byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT) begin // image 
                    data_w[7:0] = sfm_data_w ;
                    address_w = address_r + 1 ;
                    state_w = READ2 ;
                    add_to_sum() ;
                end
					 else if(byte_cnt_r>FINIS_CNT) begin // finish reading
                    state_w = IDLE ;
                    finish_w = 1 ;
                end
					 if(byte_cnt_r==37) begin
						 debug_w = sfm_data_w ;
					 end
					 /*else if(byte_cnt_w == 3) begin // for debug
							debug_w[15:8] = sfm_data_w;    // for debug
					 end                          // for debug
					 else if(byte_cnt_w == 4) begin // for debug
							debug_w[7:0] = sfm_data_w;    // for debug
					 end */
            end
        end
        READ2 : begin
            if(sfm_finish_w) begin
                byte_cnt_w = byte_cnt_r + 1 ;
                if(byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT) begin // image 
                    data_w[15:8] = sfm_data_w ;
                    write_w = 1 ;
                    state_w = READ1 ;
                    add_to_sum() ;
                end
                else if(byte_cnt_r>FINIS_CNT) begin // finish reading
                    state_w = IDLE ;
                    finish_w = 1 ;
                end
					 if(byte_cnt_r==37) begin
						 debug_w = sfm_data_w ;
					 end
            end
        end
        default : begin 
            state_w = IDLE ;
            finish_w = 0 ;
            get_rst_w = 1 ;
				get_start_w = 0 ;
				//tmp_w = 0 ;
        end
    endcase
	 
end

always_ff @(posedge i_baud or posedge i_rst) begin
	 if(i_rst) begin
		 state_r <= 0 ;
		 byte_cnt_r <= 0 ;
		 sfm_finish_r <= 0 ;
		 data_r <= 0 ;
		 finish_r <= 0 ;
		 sum1_r <= 0 ; 
		 sum2_r <= 0 ; 
		 sum3_r <= 0 ; 
		 sum4_r <= 0 ; 
		 get_rst_r <= 1 ;
		 get_start_r <= 0 ;
		 debug_r <= 0 ;
		 address_r <= 0 ;
	 end
	 else begin
		 state_r <= state_w ;
		 byte_cnt_r <= byte_cnt_w ;
		 sfm_finish_r <= sfm_finish_w ;
		 data_r <= data_w ;
		 finish_r <= finish_w ;
		 sum1_r <= sum1_w ; 
		 sum2_r <= sum2_w ; 
		 sum3_r <= sum3_w ; 
		 sum4_r <= sum4_w ; 
		 get_rst_r <= get_rst_w ;
		 get_start_r <= get_start_w ;
		 debug_r <= debug_w ;
		 address_r <= address_w ;
	 end
end

endmodule