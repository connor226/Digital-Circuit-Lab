module FP_Reader (
    input i_clk,
    input i_start,
    input i_baud,
    input i_tx_from_sfm,
    input [19:0] i_begin_addr,      // begin with this SRAM address
    output [15:0] o_sram_data,      // data from SRAM
    output [19:0] o_sram_addr,
    output o_write,                 // write data
    output o_finish
);

localparam IDLE = 0 ;
localparam READ1 = 1 ;
localparam READ2 = 2 ;
localparam START_CNT = 9 ;
localparam FINIS_CNT = 25608 ; // 8+25600

logic [1:0] state_w, state_r ;
logic [14:0] byte_cnt_w, byte_cnt_r ; // about 25600 bytes
logic [15:0] data_w, data_r ;
logic [19:0] address_w, address_r ;
logic write_w, write_r, finish_w, finish_r ;

logic [7:0] sfm_data_w ;
logic sfm_finish_w,sfm_finish_r ;


assign o_sram_data = data_w ;
assign o_sram_addr = address_w ;
assign o_write = write_w ;
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
    address_w = address_r ;
    write_w = write_r ;

    case (state_r)
        IDLE : begin
            if(i_start) begin
                state_w = READ1 ;
                byte_cnt_w = 0 ;
                data = 0 ;
                address_w = i_begin_addr - 1 ;
                write_w = 0 ;
                finish_w = 0 ;
            end
        end 
        READ1 : begin
            write_w = 0 ;
            if(!sfm_finish_r && sfm_finish_w) begin // rising edge of finish(from sfm reader)
                byte_cnt_w = byte_cnt_r + 1 ;
                if(byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT) begin // image 
                    data_w[7:0] = sfm_data_w ;
                    address_w = address_r + 1 ;
                    state_w = READ2 ;
                end
            end
        end
        READ2 : begin
            if(!sfm_finish_r && sfm_finish_w) begin
                byte_cnt_w = byte_cnt_r + 1 ;
                if(byte_cnt_r>=START_CNT && byte_cnt_r<=FINIS_CNT) begin // image 
                    data_w[15:8] = sfm_data_w ;
                    write_w = 1 ;
                    state_w = READ1 ;
                end
                else if(byte_cnt_r>FINIS_CNT) begin // finish reading
                    state_w = IDLE ;
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