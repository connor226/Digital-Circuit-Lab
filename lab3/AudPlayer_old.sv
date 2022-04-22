module AudPlayer0(
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

assign o_aud_dacdat = data_r[15] ;

always_comb begin
    state_w     = state_r ;
    data_w      = data_r ;

    case(state_r)
        idle : begin
            if(i_en && last_lr_r && (!i_daclrck)) begin  // enable and neg edge of LR clk
                state_w = outp ;
                data_w = i_dac_data ;
            end
        end

        outp : begin
            data_w = data_r << 1 ;
        end

    endcase
end


always_ff @(negedge i_rst_n or negedge i_bclk) begin 
    if(!i_rst_n) begin
        state_r <= idle ;
        data_r  <= 0 ;
        last_lr_r <= i_daclrck ;
    end
    else begin
        state_r <= state_w ;
        data_r  <= data_w ;
        last_lr_r <= i_daclrck ;
    end
end



endmodule