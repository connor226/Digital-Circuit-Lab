// send getImage commmand to sfm-V1.7
module getImage(
    input i_clk,
    input i_start,
    input i_rst,
    output o_tx_to_sfm,
    output o_finish
);

logic   [1:0]  state_w ;
logic          tx_w ;
logic   [2:0]  bit_ctr_w ;
logic   [5:0]  byte_ctr_w ;
logic          finish_w ;

reg     [1:0]  state_r ;
reg            tx_r ;
reg     [2:0]  bit_ctr_r ;
reg     [5:0]  byte_ctr_r ;
reg            finish_r ;


localparam  [127:0] cmd = 128'b1111_0101_0000_1001_0000_0000_0000_0000_0000_0000_0000_0000_0000_1001_1111_0101_1111_0101_0010_0100_0000_0000_0000_0000_0000_0000_0000_0000_0010_0100_1111_0101;
// localparam  [127:0] cmd = 128'b1111_0101_0010_0100_0000_0000_0000_0000_0000_0000_0000_0000_0010_0100_1111_0101_1111_0101_0000_1001_0000_0000_0000_0000_0000_0000_0000_0000_0000_1001_1111_0101;
localparam STATE_IDLE = 0 ;
localparam STATE_SEND = 1 ;
localparam STATE_HOLD = 2 ;



assign o_tx_to_sfm = tx_r ;
assign o_finish = finish_r ;

always_comb begin
    
    bit_ctr_w = bit_ctr_r ;
    byte_ctr_w = byte_ctr_r ;
    tx_w = tx_r ;
    state_w = state_r ;
    finish_w = finish_r ;


    case(state_r)

        STATE_IDLE : begin
            if(!i_start && (byte_ctr_r == 0)) begin
                state_w = STATE_IDLE;
                tx_w = 1 ;
            end

            else        begin
                state_w = STATE_SEND;
                tx_w = 0 ; 
            end
        end

        STATE_SEND : begin
            if(bit_ctr_r!=7) begin
                tx_w = cmd[8*byte_ctr_r+bit_ctr_r] ;
                bit_ctr_w = bit_ctr_r + 1 ;
                state_w =  STATE_SEND ;
            end

            else            begin
                tx_w = cmd[8*byte_ctr_r+bit_ctr_r] ;
                byte_ctr_w = byte_ctr_r + 1 ;
                bit_ctr_w = 0 ;
                state_w = STATE_HOLD;
            end    
        end

        STATE_HOLD : begin
            if(byte_ctr_r!=8) begin  // 16->8
                state_w = STATE_IDLE;
                tx_w = 1;
            end
            else              begin              //end
                state_w = STATE_HOLD;
                finish_w = 1 ;
                tx_w = 1;
            end
        end
        
    endcase
end

always_ff @( posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        state_r <= 0 ;
        bit_ctr_r <= 0 ;
        byte_ctr_r <= 0 ;
        tx_r <= 1 ;
        finish_r <= 0 ;
    end
    else begin
		  state_r <= state_w ;
        bit_ctr_r <= bit_ctr_w ;
        byte_ctr_r <= byte_ctr_w ;
        tx_r <= tx_w ;
        finish_r <= finish_w ;
    end
end

endmodule