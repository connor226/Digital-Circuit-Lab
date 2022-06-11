module Core_Slope(
    input i_clk,
    input i_start,
    input [0:15] i_data,
    output [10:0] o_sram_address,
    output signed [15:0] o_slope,                                  // format : slope = 1.327, o_slope = 1327
    output o_finish
);

localparam IDLE = 0 ;
localparam READ = 1 ;
localparam CALC = 2 ;


logic [1:0]  state_w, state_r ;
logic [10:0] address_w, address_r ;
logic [15:0] slope_w, slope_r ;
logic        finish_w, finish_r ;

logic [7:0] row_w, row_r, col_w, col_r ;                    // 160 rows, 10 columns
logic       hor_val_w, hor_val_r ;                          // the value exactly on col = 2,3,4,5,6,7,8
logic [0:6] ver_val_w, ver_val_r ;                          // the value exactly on row = 32,48,64,80,96,112,128
logic [9:0] hor_cnt_w, hor_cnt_r, ver_cnt_w, ver_cnt_r ;
logic       pos_val_w, pos_val_r, neg_val_w, neg_val_r ;

int sgn_cnt_w, sgn_cnt_r ;

assign o_sram_address = address_r ;
assign o_slope = slope_w ;
assign o_finish = finish_w ;

task arr_update;
    if(col_r*16<=row_r && row_r<(col_r+1)*16) begin         // left-up <--> right-down
        neg_val_w = i_data[row_r-col_r*16] ;
        if(col_r>0 && neg_val_w^neg_val_r)
            sgn_cnt_w = sgn_cnt_w + 1 ;
    end
    if(col_r*16<=(159-row_r) && (159-row_r)<(col_r+1)*16) begin
        pos_val_w = i_data[(159-row_r)-col_r*16] ;
        if(col_r>0 && pos_val_w^pos_val_r)
            sgn_cnt_w = sgn_cnt_w - 1 ;
    end
endtask

task vertical;                                              // deal with vertical count update
    if(col_r>1 && col_r<9) begin                            // col 32~128 and not the first row
        if(row_r>0 && i_data[0]^ver_val_r[col_r-2]) begin   // current val is different from last value : cnt++
            ver_cnt_w = ver_cnt_r + 1;
        end
        ver_val_w[col_r-2] = i_data[0];                     // update last value
    end
endtask

task xor_16bit;
    for(int i=1; i<16; i=i+1) begin
        if(i_data[i-1]^i_data[i])
            hor_cnt_w = hor_cnt_w + 1;                      // note: we should use cnt_wire, since there could be multiple changes
    end
    if((col_r>0) && (i_data[0]^hor_val_r)) begin            // only second column(or afterward cols) can compare with last val
        hor_cnt_w = hor_cnt_w + 1;
    end
    hor_val_w = i_data[15];
endtask

task set(bit mode);
    if(mode) begin
        row_w=0; col_w=0;
        hor_val_w=0; ver_val_w=0;
        ver_cnt_w=0; hor_cnt_w=0;
        pos_val_w=0; neg_val_w=0;
        sgn_cnt_w=0;
        finish_w=0;
        slope_w=0;
        address_w=0;
        state_w=READ;
    end
    else begin
        row_w=row_r; col_w=col_r;
        hor_val_w=hor_val_r; ver_val_w=ver_val_r;
        ver_cnt_w=ver_cnt_r; hor_cnt_w=hor_cnt_r;
        pos_val_w=pos_val_r; neg_val_w=neg_val_r;
        sgn_cnt_w=sgn_cnt_r;
        finish_w=finish_r;
        slope_w=slope_r;
        address_w=address_r;
        state_w=state_r;
    end
endtask

always_comb begin
    set(1'b0);
    case(state_r)
        IDLE : begin
            if(i_start) begin
                set(1'b1);
            end
        end
        READ : begin
            arr_update();
            vertical();
            if(row_r>31 && row_r<129 && ~(|row_r[3:0])) begin
                xor_16bit();
            end
            if(col_r==9) begin                              // already at the rightmost column
                col_w = 0;
                row_w = row_r + 1;
                if(row_r==159) begin                        // already at the bottom row -> finish all picture
                    state_w = CALC ;
                end                 
            end
            else begin
                col_w = col_r + 1;
            end
            address_w = address_r + 1;
        end
        CALC : begin
            if(sgn_cnt_w>0)
                slope_w = (1000*hor_cnt_r)/(ver_cnt_r);
            else
                slope_w = signed'((1000*hor_cnt_r)/(ver_cnt_r)*signed'(-1));
            finish_w = 1;
            state_w = IDLE;
        end
        default : begin
            state_w = IDLE ;
            finish_w = 0 ;
        end
    endcase
end

always_ff @(posedge i_clk) begin
    row_r<=row_w; col_r<=col_w;
    hor_val_r<=hor_val_w; ver_val_r<=ver_val_w;
    hor_cnt_r<=hor_cnt_w; ver_cnt_r<=ver_cnt_w;
    pos_val_r<=pos_val_w; neg_val_r<=neg_val_w;
    sgn_cnt_r<=sgn_cnt_w;

    finish_r<=finish_w;
    slope_r<=slope_w;
    address_r<=address_w;
    state_r<=state_w;
end

endmodule