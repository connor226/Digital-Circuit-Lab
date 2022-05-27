module ADconvert(
    input i_clk,
    input i_rst_n,
    input i_start,
    input  [7:0] threshold1,
    input  [7:0] threshold2,
    input  [7:0] threshold3,
    input  [7:0] threshold4,
    input  [15:0] data,
    input  [19:0] i_begin_addr,
    output [7:0] row,
    output [7:0] column,
    output o_finished,
    output [19:0] o_sram_addr,
    output [1:0] o_data
);

localparam S_IDLE = 1'b0, S_CALC = 1'b1;

logic state_w;
logic [19:0] sram_addr_w;
logic [7:0] row_w, column_w;


reg   state_r;
reg   [19:0] sram_addr_r;
reg   [7:0] row_r, column_r;

assign row = row_r;
assign column = column_r << 1;

always_comb begin
    state_w = state_r;
    sram_addr_w = sram_addr_r;
    row_w = row_r;
    column_w = column_r;
    case(state_r)
        S_IDLE: begin
            o_finished = 1'b1;
            o_data = 1'b0;
            if(i_start) begin
                state_w = S_CALC;
                o_finished = 1'b0;
                sram_addr_w = i_begin_addr;
                row_w = 0;
                column_w = 0;
            end
        end
        S_CALC: begin
            o_finished = 1'b0;
            if(row_r >= 8'd80 && column_r >= 8'd40) begin
                o_data = {(data[15:8] > threshold4), (data[7:0] > threshold4)};
            end
            else if(row_r >= 8'd80 && column_r < 8'd40) begin
                o_data = {(data[15:8] > threshold3), (data[7:0] > threshold3)};
            end
            else if(row_r < 8'd80 && column_r >= 8'd40) begin
                o_data = {(data[15:8] > threshold2), (data[7:0] > threshold2)};
            end
            else if(row_r < 8'd80 && column_r < 8'd40) begin
                o_data = {(data[15:8] > threshold1), (data[7:0] > threshold1)};
            end
            sram_addr_w = sram_addr_r + 1;
            column_w = column_r + 1;
            if(column_w == 8'd80) begin
                row_w = row_r + 1;
                column_w = 8'd0;
            end
            if(row_w == 8'd160) begin
                state_w = S_IDLE;
            end
        end
    endcase
end

always_ff @( posedge i_clk or negedge i_rst_n ) begin
    if(!i_rst_n) begin
        state_r <= S_IDLE;
        sram_addr_r <= 20'd0;
        row_r <= 8'd0;
        column_r <= 8'd0;
    end
    else begin
        state_r <= state_w;
        sram_addr_r <= sram_addr_w;
        row_r <= row_w;
        column_r <= column_w;
    end
end

endmodule