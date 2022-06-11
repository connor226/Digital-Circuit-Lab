module Reader (
    input i_clk,
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
    output o_tx_to_sfm
);

localparam IDLE = 0 ;
localparam SEND_CMD = 1 ;
localparam READ = 2 ;

logic [1:0] state_w, state_r ;
logic finish_ask, finish_read, start_ask, start_read, finish ;

assign o_finish = finish ;


FP_Reader fp1 (
    i_clk(i_clk),
    i_start(start_read),
    i_baud(i_baud),
    i_rx_from_sfm(i_rx_from_sfm),
    i_begin_addr(i_begin_addr),      // begin with this SRAM address
    o_sram_data(o_sram_data),      // data from SRAM
    o_sram_addr(o_sram_addr),
    o_write(o_write),                 // write data
    o_finish(finish_read),
    o_avg1(o_avg1),
    o_avg2(o_avg2),
    o_avg3(o_avg3),
    o_avg4(o_avg4),
);

getImage get1(
    i_clk(i_baud),
    i_start(start_ask),
    o_tx_to_sfm(o_tx_to_sfm),
    o_finish(finish_ask)
);

always_comb begin
    state_w = state_r ;
    finish = 0 ;

    case(state_r)
        IDLE : begin
            if(i_start) begin
                start_ask = 1 ;
                state_w   = SEND_CMD ;
            end
        end
        SEND_CMD : begin
            if(finish_ask) begin
                start_read  = 1 ;
                start_ask   = 0 ;
                start_read  = 1 ;
                state_w = READ ;
            end
        end
        READ : begin
            if(finish_read) begin
                start_read = 0 ;
                state_w = IDLE ;
                finish = 1 ;
            end
        end
    endcase
end

always_ff @(posedge i_clk) begin
    state_r => state_w ;
end

endmodule