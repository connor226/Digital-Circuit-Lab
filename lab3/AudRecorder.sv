module AudRecorder(
    input         i_rst_n      , 
	input         i_clk        ,
	input         i_lrc        ,
	input         i_start      ,
	input         i_pause      ,
	input         i_stop       ,
	input         i_data       ,
	output [19:0] o_address    ,
	output [15:0] o_data
);

localparam S_IDLE = 2'b00, S_RECORDING = 2'b01, S_PAUSE = 2'b11;

logic        hold_w             ;
logic [1:0]  state_w            ;
logic [4:0]  bit_counter_w      ;
logic [15:0] data_w             ;
logic [19:0] address_counter_w  ;

reg          hold_r             ;
reg   [1:0]  state_r            ;
reg   [4:0]  bit_counter_r      ;
reg   [15:0] data_r             ;
reg   [19:0] address_counter_r  ;

assign o_address = address_counter_r;
assign o_data = (bit_counter_r[4] ? data_r : 16'bz);

always_comb begin
    state_w = state_r;
    data_w = data_r;
    bit_counter_w = bit_counter_r;
    address_counter_w = address_counter_r;
    hold_w = hold_r;

    case(state_r)
        S_IDLE: begin
            if(i_start) begin
                state_w = S_RECORDING;
                bit_counter_w = 5'd0;
                data_w = 16'd0;
                address_counter_w = 20'd0;
                hold_w = 1'b1;
            end
        end
        S_RECORDING: begin
            if(i_pause) begin
                state_w = S_PAUSE;
            end
            else  if(i_stop) begin
                state_w = S_IDLE;
            end
            else  if(!i_lrc & hold_r) begin
                hold_w = 0;
            end
            else  if(!i_lrc & !(bit_counter_r[4])) begin // read 16 bits and then stop reading
                bit_counter_w = bit_counter_r + 1;
                data_w = data_r << 1;
                data_w[0] = i_data;
            end
            else  if(i_lrc) begin // reset for next right channel in
                hold_w = 1;
                if(&address_counter_r) begin // no more available address, forced stop
                    state_w = S_IDLE;
                end
                else if(bit_counter_r[4]) begin
                    address_counter_w = address_counter_r + 1;
                end
                bit_counter_w = 5'd0;
            end
        end
        S_PAUSE: begin
            bit_counter_w = 5'd0;
            data_w = 16'd0;
            if(i_start) begin
                state_w = S_RECORDING;
            end
            if(i_stop) begin
                state_w = S_IDLE;
            end
        end
        default begin
            state_w = S_IDLE;
        end
    endcase
end

always_ff @( negedge i_rst_n or negedge i_clk ) begin
    if(!i_rst_n) begin
        state_r <= S_IDLE;
        bit_counter_r <= 5'd0;
        data_r <= 16'd0;
        address_counter_r <= 20'd0;
        hold_r <= 0;
    end
    else begin
        state_r <= state_w;
        data_r <= data_w;
        hold_r <= hold_w;
        bit_counter_r <= bit_counter_w;
        address_counter_r <= address_counter_w;
    end
end

endmodule
