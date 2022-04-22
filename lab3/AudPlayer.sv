module AudPlayer(
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	output o_aud_dacdat
);

localparam idle = 0 ;
localparam outp = 1 ;

logic state_r, state_w ;
logic [15:0] data_r, data_w ;  // 16 values
logic last_lr_r ;
logic [3:0] ctr_w, ctr_r ;

assign o_aud_dacdat = data_r[15] ;

always_comb begin
    state_w     = state_r ;
    data_w      = data_r ;
    ctr_w       = ctr_r ;

    case(state_r)
        idle : begin
            if(i_en && last_lr_r && (!i_daclrck)) begin  // enable and neg edge of LR clk
                state_w = outp ;
                data_w  = i_dac_data ;
                ctr_w   = 0 ;
            end
        end

        outp : begin
            data_w = data_r << 1 ;
            if(&ctr_r) begin    // 16 bits all transmitted
                ctr_w = 0 ;
                state_w = idle ;
            end
            else begin
                ctr_w = ctr_r + 1 ;
            end
        end

    endcase
end


always_ff @(negedge i_rst_n or negedge i_bclk) begin 
    if(!i_rst_n) begin
        state_r <= idle ;
        data_r  <= 0 ;
        last_lr_r <= i_daclrck ;
        ctr_r   <= 0 ;
    end
    else begin
        state_r <= state_w ;
        data_r  <= data_w ;
        last_lr_r <= i_daclrck ;
        ctr_r   <= ctr_w ;
    end
end



endmodule