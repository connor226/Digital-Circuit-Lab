module I2cInitializer (
	input i_rst_n,
	input i_clk,
	input i_start,
	output o_finished,
	output o_sclk,
	output o_sdat,
	output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
);

//HM8731 address
localparam ADDR_HM8731 = 8'b0011_0100 ;
//Reset address + initialization
localparam RESET_1 = 8'b0001_1110 ;
localparam RESET_2 = 8'b0000_0000 ;
//A_audio path control address + initialization
localparam A_AUDIO_PATH_CONTROL_1 = 8'b0000_1000 ;
localparam A_AUDIO_PATH_CONTROL_2 = 8'b0001_0101 ;
//
localparam D_AUDIO_PATH_CONTROL_1 = 8'b0000_1010 ;
localparam D_AUDIO_PATH_CONTROL_2 = 8'b0000_0000 ;
//
localparam POWER_DOWN_CONTROL_1 = 8'b0000_1100 ;
localparam POWER_DOWN_CONTROL_2 = 8'b0000_0000 ;
//
localparam D_AUDIO_INTERFACE_FORMAT_1 = 8'b0000_1110 ;
localparam D_AUDIO_INTERFACE_FORMAT_2 = 8'b0100_0010 ;
//
localparam SAMPLING_CONTROL_1 = 8'b0001_0000 ;
localparam SAMPLING_CONTROL_2 = 8'b0001_1001 ;
//
localparam ACTIVE_CONTROL_1 = 8'b0001_0010 ;
localparam ACTIVE_CONTROL_2 = 8'b0000_0001 ;




//state
localparam STATE_IDLE = 0 ;
localparam STATE_HM8731= 1 ;
localparam STATE_RESET_1 = 2 ;
localparam STATE_RESET_2 = 3 ;
localparam STATE_A_AUDIO_PATH_CONTROL_1 = 4 ;
localparam STATE_A_AUDIO_PATH_CONTROL_2 = 5 ;
localparam STATE_D_AUDIO_PATH_CONTROL_1 = 6 ;
localparam STATE_D_AUDIO_PATH_CONTROL_2 = 7 ;
localparam STATE_POWER_DOWN_CONTROL_1 = 8 ;
localparam STATE_POWER_DOWN_CONTROL_2 = 9 ;
localparam STATE_D_AUDIO_INTERFACE_FORMAT_1 = 10 ;
localparam STATE_D_AUDIO_INTERFACE_FORMAT_2 = 11 ;
localparam STATE_SAMPLING_CONTROL_1 = 12 ;
localparam STATE_SAMPLING_CONTROL_2 = 13 ;
localparam STATE_ACTIVE_CONTROL_1 = 14 ;
localparam STATE_ACTIVE_CONTROL_2 = 15 ;

localparam STATE_READ_DATA = 16 ;
localparam STATE_END_SET1 = 17 ;
localparam STATE_END_WAIT = 18 ;
localparam STATE_END_SET0 = 19 ;
localparam STATE_END = 23 ;
localparam STATE_ACK = 20 ;
localparam STATE_ACK_WAIT = 21 ;
localparam STATE_START = 22 ;
localparam STATE_RESTART = 24 ;


//registers
reg[4:0] state_r ;
reg[4:0] ack_back_to_state_r ; 
reg[4:0] read_back_to_state_r ;
reg[2:0] ctr_r ; // sda 8 bits
reg finished_r ;
reg sda_r ;
reg[4:0] end_back_to_state_r;

//wires
logic[4:0] state_w ;
logic[4:0] ack_back_to_state_w ;
logic[4:0] read_back_to_state_w ; 
logic[4:0] end_back_to_state_w ;
logic[2:0] ctr_w ; // sda 8 bits
logic sda_w ;
logic oen_w ;
logic sclk_w ;
logic finished_w ; 


//outputs
assign o_sdat = sda_w ;
assign o_finished = finished_r ;
assign o_sclk =  sclk_w ;
assign o_oen = oen_w ;


always_comb begin
		
	state_w = state_r ;
	ack_back_to_state_w = ack_back_to_state_r ;
	read_back_to_state_w = read_back_to_state_r ;
	end_back_to_state_w = end_back_to_state_r ;
	ctr_w = ctr_r ;
	sda_w = sda_r ;
	finished_w = finished_r ;
	sclk_w = 0 ;
	oen_w = 1 ;


		case(state_r) 
			
            STATE_IDLE : begin
				if(!i_start) begin
					state_w = STATE_IDLE ;
					oen_w = 1 ;
					sda_w = 0 ;
				end
				else begin 
					state_w = STATE_READ_DATA ;
					sda_w = 1 ;
					sclk_w = 1 ;
					read_back_to_state_w = STATE_START ;
					ctr_w = 7 ;
					oen_w = 1 ;
				end
			end

			STATE_START : begin
				sda_w = 0 ;
				sclk_w = 1 ;
				oen_w = 1 ;
				state_w = STATE_HM8731 ;
			end

			STATE_END_SET1 : begin
				sda_w = 1 ;
				oen_w = 0 ;
				sclk_w = 0 ;
				state_w = STATE_END_WAIT ;
			end

			STATE_END_WAIT : begin
				sda_w = 1 ;
				oen_w = 0 ;
				sclk_w = 1 ;
				ctr_w = 7 ;
				state_w = ack_back_to_state_r ;
			end

			STATE_END_SET0 : begin
				sda_w = 0 ;
				oen_w = 1 ;
				state_w = STATE_END ;
			end

			STATE_END : begin
				sda_w = sda_r ;
				sclk_w = 1 ;
				oen_w = 1 ;
				state_w = STATE_RESTART ;
				read_back_to_state_w = STATE_HM8731 ;
			end

			STATE_RESTART : begin
				sda_w = 1 ;
				sclk_w = 1 ;
				oen_w = 1 ;
				state_w = STATE_START ;
			end

			STATE_ACK : begin
				oen_w = 0 ;
				sda_w = 0 ;
				sclk_w = 1 ;
				state_w = STATE_READ_DATA ; 
				read_back_to_state_w = ack_back_to_state_r ;
				ctr_w = 7 ;
			end

			STATE_READ_DATA : begin
				sclk_w = 1 ;
				state_w = read_back_to_state_r ;
			end 


			STATE_HM8731 : begin
				if(ctr_r > 0) begin	
					sda_w = ADDR_HM8731[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_HM8731 ;
				end
				else begin
					sda_w = ADDR_HM8731[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_END_SET1 ;
                    ack_back_to_state_w = end_back_to_state_r ; 
		
				end
			end



			STATE_RESET_1 : begin
				if(ctr_r > 0) begin	
					sda_w = RESET_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_RESET_1 ;
				end
				else begin
					sda_w = RESET_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_RESET_2 : begin
				if(ctr_r > 0) begin	
					sda_w = RESET_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_RESET_2 ;
				end
				else begin
					sda_w = RESET_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end

			STATE_A_AUDIO_PATH_CONTROL_1 : begin
				if(ctr_r > 0) begin	
					sda_w = A_AUDIO_PATH_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_A_AUDIO_PATH_CONTROL_1 ;
				end
				else begin
					sda_w = A_AUDIO_PATH_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_A_AUDIO_PATH_CONTROL_2 : begin
				if(ctr_r > 0) begin	
					sda_w = A_AUDIO_PATH_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_A_AUDIO_PATH_CONTROL_2 ;
				end
				else begin
					sda_w = A_AUDIO_PATH_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end

			STATE_D_AUDIO_PATH_CONTROL_1 : begin
				if(ctr_r > 0) begin	
					sda_w = D_AUDIO_PATH_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_D_AUDIO_PATH_CONTROL_1 ;
				end
				else begin
					sda_w = D_AUDIO_PATH_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_D_AUDIO_PATH_CONTROL_2 : begin
				if(ctr_r > 0) begin	
					sda_w = D_AUDIO_PATH_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_D_AUDIO_PATH_CONTROL_2 ;
				end
				else begin
					sda_w = D_AUDIO_PATH_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end
			
			STATE_POWER_DOWN_CONTROL_1 : begin
				if(ctr_r > 0) begin	
					sda_w = POWER_DOWN_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_POWER_DOWN_CONTROL_1 ;
				end
				else begin
					sda_w = POWER_DOWN_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_POWER_DOWN_CONTROL_2 : begin
				if(ctr_r > 0) begin	
					sda_w = POWER_DOWN_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_POWER_DOWN_CONTROL_2 ;
				end
				else begin
					sda_w = POWER_DOWN_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end
		
			STATE_D_AUDIO_INTERFACE_FORMAT_1 : begin
				if(ctr_r > 0) begin	
					sda_w = D_AUDIO_INTERFACE_FORMAT_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_D_AUDIO_INTERFACE_FORMAT_1 ;
				end
				else begin
					sda_w = D_AUDIO_INTERFACE_FORMAT_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_D_AUDIO_INTERFACE_FORMAT_2 : begin
				if(ctr_r > 0) begin	
					sda_w = D_AUDIO_INTERFACE_FORMAT_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_D_AUDIO_INTERFACE_FORMAT_2 ;
				end
				else begin
					sda_w = D_AUDIO_INTERFACE_FORMAT_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end

			STATE_SAMPLING_CONTROL_1 : begin
				if(ctr_r > 0) begin	
					sda_w = SAMPLING_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_SAMPLING_CONTROL_1 ;
				end
				else begin
					sda_w = SAMPLING_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_SAMPLING_CONTROL_2 : begin
				if(ctr_r > 0) begin	
					sda_w = SAMPLING_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_SAMPLING_CONTROL_2 ;
				end
				else begin
					sda_w = SAMPLING_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = state_r + 1 ;
				end
			end

			STATE_ACTIVE_CONTROL_1 : begin
				if(ctr_r > 0) begin	
					sda_w = ACTIVE_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_ACTIVE_CONTROL_1 ;
				end
				else begin
					sda_w = ACTIVE_CONTROL_1[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = state_r + 1 ; 
					read_back_to_state_w = STATE_END_SET1 ;
				end
			end

			STATE_ACTIVE_CONTROL_2 : begin
				if(ctr_r > 0) begin	
					sda_w = ACTIVE_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					ctr_w = ctr_r - 1 ;
					state_w = STATE_READ_DATA ;
					read_back_to_state_w = STATE_ACTIVE_CONTROL_2 ;
				end
				else begin
					sda_w = ACTIVE_CONTROL_2[ctr_r] ;
					sclk_w = 0 ;
					state_w = STATE_READ_DATA ;
                    ack_back_to_state_w = STATE_END_SET0 ; 
					read_back_to_state_w = STATE_END_SET1 ;
					end_back_to_state_w = STATE_IDLE ;
					finished_w = 1 ;
				end
			end

        endcase
end



always_ff @(posedge i_clk or negedge i_rst_n) begin

	if(!i_rst_n) begin
		state_r <= 4'b0000 ;
		ack_back_to_state_r <= 1 ;
		finished_r <= 0 ;
		sda_r <= 0 ;
		end_back_to_state_r <= 2 ;
	end
	
	else begin
		state_r <= state_w ;
		ctr_r <= ctr_w ;
		ack_back_to_state_r <= ack_back_to_state_w ;
		finished_r <= finished_w ;
		read_back_to_state_r <= read_back_to_state_w ;
		end_back_to_state_r <= end_back_to_state_w ;
		sda_r <= sda_w ;
		
	end
end


endmodule