module SFM_reader (
    input i_clk,
    input i_rx_from_sfm,
    output [7:0] o_data,
    output o_finish
);

logic state_w, state_r ;  // 0 = idle, 1 = reading
logic [2:0] cnt_w, cnt_r=0 ;
logic [7:0] data_w, data_r ;
logic pre_data_r, finish_r, finish_w ;

assign o_data = data_r ;
assign o_finish = finish_r ;

always_comb begin
    cnt_w = cnt_r ;
    data_w = data_r ;
    state_w = state_r ;
	finish_w = finish_r ;

    case(state_r)
        0 : begin
				finish_w = 0 ;
            cnt_w = 0 ;
            data_w = 0 ;
            if(pre_data_r && !i_rx_from_sfm) begin
                state_w = 1 ;
            end
        end

        1 : begin
            data_w[cnt_r] = i_rx_from_sfm ;
            if(cnt_r < 7) begin
                cnt_w = cnt_r + 1 ;
            end
            else begin
                state_w = 0 ;
                finish_w = 1 ;
            end
        end
        default : begin
            state_w = 0 ;
            finish_w = 0 ;
        end
        
        
    endcase
end

always_ff @( posedge i_clk ) begin
    state_r <= state_w ;
    cnt_r <= cnt_w ;
    data_r <= data_w ;
    pre_data_r <= i_rx_from_sfm ;
    finish_r <= finish_w ;
end

endmodule