module Core_Feat(
    input i_clk,
    input i_start,
    input [0:15] i_sram_data,
    input [19:0] i_begin_address,
    input [0:159][0:159] i_full_fp,
    output [19:0] o_sram_address,
    output int o_score,                                          // format : 10000*IoU
    output o_control_start,                                         // send signal to the top core
    output o_finish
);

localparam IDLE = 0;
localparam READ = 1;
localparam PROP = 2;
localparam POOL = 3;
localparam CALC = 4;

logic [2:0]  state_w, state_r ;
logic        fin_1st_pic_w, fin_1st_pic_r ;
logic [19:0] address_w, address_r ;
logic        finish, control ;

logic [0:159][0:159] board_w, board_r, p_board_w, p_board_r ;       // upper left is (0,0)
logic [0:29][0:29]   pool_board1_w, pool_board1_r ;                 // 30*30 pooling with 5*5 window
logic [0:29][0:29]   pool_board2_w, pool_board2_r ;                 
logic [7:0] row_w, row_r, col_w, col_r ;                            // start at 0 to 159
int inter_w, inter_r, union_w, union_r ;                    // at most 30*30 counts

assign o_sram_address = address_r ;
assign o_score = ((100*inter_w)/(union_w)) ;
assign o_control_start = control ;
assign o_finish = finish ;

task read_data;
    board_w[row_r][col_r+:16] = i_sram_data ;
    address_w = address_r + 1 ;
    if(col_r>142) begin                                             // last column to read is 144
        col_w = 0 ;
        row_w = row_r + 1 ;
    end
    else begin
        col_w = col_r + 16 ;
    end
endtask

task apply_prop;
    p_board_w[row_r][col_r] = ~board_r[row_r][col_r] && ~proportion_5_5(board_r,row_r,col_r,11) ;
    if(col_r==157) begin                                             // 157 is the last
        col_w = 2 ;
        row_w = row_r + 1 ;
    end
    else begin
        col_w = col_r + 1 ;
    end
endtask

task apply_pool;                                                    // row,col range from 0 to 29
    if(!fin_1st_pic_r) begin
        pool_board1_w[row_r][col_r] = ~proportion_5_5(p_board_r,5*row_r+2,5*col_r+2, 23) ;
    end
    else begin
        pool_board2_w[row_r][col_r] = ~proportion_5_5(p_board_r,5*row_r+2,5*col_r+2, 23) ;
    end
    if(col_r==29) begin
        col_w = 0 ;
        row_w = row_r + 1 ;
    end
    else begin
        col_w = col_r + 1 ;
    end
endtask

function automatic bit proportion_5_5(                              // true if #(black) exceeds threshold
    const ref [0:159][0:159] arr,
    input [7:0] row, col,
    input [4:0] threshold
);
    logic [4:0] cnt ;
    cnt = 0 ;
    for(int i=-2;i<=2;i=i+1) begin
        for(int j=-2;j<=2;j=j+1) begin
            if(!arr[row+i][col+j]) cnt = cnt + 1 ;
        end 
    end
    return cnt > threshold ;
endfunction

task calc_IoU;
    if(pool_board1_r[row_r][col_r] && pool_board2_r[row_r][col_r]) begin
        inter_w = inter_r + 1 ;
    end
    if(pool_board1_r[row_r][col_r] || pool_board2_r[row_r][col_r]) begin
        union_w = union_r + 1 ;
    end
    if(col_r==29) begin
        col_w = 0 ;
        row_w = row_r + 1 ;
    end
    else begin
        col_w = col_r + 1 ;
    end
endtask

task set(bit mode);
    control = 0 ;
    finish = 0 ;
    if(mode) begin
        state_w = PROP ;
        fin_1st_pic_w = 0 ;
        address_w = i_begin_address ;

        board_w = i_full_fp ;
        p_board_w = 0 ;
        pool_board1_w = 0 ; pool_board2_w = 0 ;
        row_w = 2 ; col_w = 2 ;
        inter_w = 0 ; union_w = 0 ;
    end
    else begin
        state_w = state_r ;
        fin_1st_pic_w = fin_1st_pic_r ;
        address_w = address_r ;

        board_w = board_r ;
        p_board_w = p_board_r ;
        pool_board1_w = pool_board1_r ; pool_board2_w = pool_board2_r ;
        row_w = row_r ; col_w = col_r ;
        inter_w = inter_r ; union_w = union_r ;
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
            read_data();
            if(row_w>159) begin                                     // finish reading
                state_w = PROP ;
                col_w = 2 ;                                         // we are starting at (2,2) as 5*5 window's midpoint
                row_w = 2 ;
            end
        end
        PROP : begin
            apply_prop();
            if(row_w>157) begin
                state_w = POOL ;
                col_w = 0 ;
                row_w = 0 ;
            end
        end
        POOL : begin
            apply_pool();
            if(row_w>29) begin
                col_w = 0 ;
                row_w = 0 ;
                if(fin_1st_pic_r) begin
                    state_w = CALC ;
                end
                else begin
                    state_w = READ ;
                    fin_1st_pic_w = 1 ;
                    control = 1 ;                                   // READING will start next clock
                end
            end
        end
        CALC : begin
            calc_IoU();
            if(row_w>29) begin
                state_w = IDLE ;
                finish = 1 ;
            end
        end
        default : begin
            state_w = 0 ;
        end
    endcase
end

always_ff @(posedge i_clk) begin
    state_r <= state_w ;
    fin_1st_pic_r <= fin_1st_pic_w ;
    address_r <= address_w ;

    board_r <= board_w ;
    p_board_r <= p_board_w ;
    pool_board1_r <= pool_board1_w ; pool_board2_r <= pool_board2_w ;
    row_r <= row_w ; col_r <= col_w ;
    inter_r <= inter_w ; union_r <= union_w ;
end

endmodule