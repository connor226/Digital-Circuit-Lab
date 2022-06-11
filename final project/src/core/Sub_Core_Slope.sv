module Sub_Core_Slope(
    input i_clk,
    input i_start,
    input i_data,
    output [15:0] o_slope,
    output o_finish
);

localparam IDLE = 0 ;
localparam READ = 1 ;
localparam CALC = 2 ;

logic [1:0] state_w, state_r ;
logic finish_r, finish_w ;

logic [7:0] i_w, i_r, j_w, j_r ;    // position : upper left = (0,0)    // (0,2) -> i=0, j=1
logic [4:0] hor_val_w, hor_val_r ;  // the value exactly on col = 40,60,80,100,120
logic [4:0] ver_val_w, ver_val_r ;  // the value exactly on row = 40,60,80,100,120
logic [9:0] hor_cnt_w, hor_cnt_r, ver_cnt_w, ver_cnt_r ;


task horizontal;
    case(row_r)
        40 : begin
            hor_cnt_w = i_data
            
        end
        60 : begin
            
        end
        80 : begin
            
        end
        100 : begin
            
        end
        120 : begin
            
        end
    endcase


endtask








always_comb begin
    
    case(state_r)
        IDLE : begin
            if(i_start) begin
                i_w=0; j_w=0;
                hor_val_w=0; ver_val_w=0;
                ver_cnt_w=0; ver_cnt_w=0;
                finish_w=0;
                data_w=0;
                state_w=READ;
            end
        end
        READ : begin
            
        end






        
        default : begin
            state_w = IDLE ;
            finish_w = 0 ;
        end
    endcase



end


















endmodule