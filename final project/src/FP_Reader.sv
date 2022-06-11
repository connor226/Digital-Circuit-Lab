module FP_Reader (
    input i_clk,
    input i_start,
    input i_baud,
    input i_tx_from_sfm,
    output [8*160*160:0] o_data,
    output o_finish,
);

localparam IDLE = 0 ;
localparam READ = 1 ;
localparam START_CNT = 9 ;
localparam FINIS_CNT = 25608 ; // 8+25600

logic state_w, state_r, finish_w, finish_r ;
logic [14:0] byte_cnt_w, byte_cnt_r ; // about 25600 bytes
logic [8*160*160:0] data_w, data_r ;
logic [7:0] sfm_data_w ;
logic sfm_finish_w,sfm_finish_r ;

assign o_data = data_w ;
assign o_finish = finish_w ;

SFM_reader R1(
    .i_clk(i_baud),
    .i_tx_from_sfm(i_tx_from_sfm),
    .o_data(sfm_data_w),
    .o_finish(sfm_finish_w)
);

always_comb begin
    state_w = state_r ;
    byte_cnt_w = byte_cnt_r ;
    data_w = data_r ;
    finish_w = finish_r ;

    case (state_r)
        IDLE : begin
            if(i_start) begin
                state_w = READ ;
                byte_cnt_w = 0 ;
                finish_w = 0 ;
            end
        end 
        READ : begin
            if(!sfm_finish_r && sfm_finish_w) begin // rising edge of finish(from sfm reader)
                byte_cnt_w = byte_cnt_r + 1 ;
                if(byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT) begin // image 
                    data_w = data_w<<8 ;
                    data_w[7:0] = sfm_data_w ;
                end
                if(byte_cnt_w>FINIS_CNT+2) begin // finish reading
                    state_w = IDLE ;
                    byte_cnt_w = 0 ;
                    finish_w = 1 ;
                end
            end
        end
        default : begin 
            state_w = IDLE ;
            finish_w = 0 ;
        end
    endcase

end

always_ff @(i_clk) begin
    state_r <= state_w ;
    byte_cnt_r <= byte_cnt_w ;
    sfm_finish_r <= sfm_finish_w ;
    data_r <= data_w ;
    finish_r <= finish_w ;
end

endmodule