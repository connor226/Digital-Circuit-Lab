module Core(
    input i_clk,
    input i_start,
    input [0:15] i_sram_data,
    input [19:0] i_begin_address,
    input [0:159][0:159] i_full_fp,
    output [19:0] o_sram_address,
    output [15:0] o_match,						// output the score, if slpoe too wrong, score = 0
    output o_finish
);

localparam IDLE = 0 ;
localparam FIRST_FP = 1 ;
localparam SECON_FP = 2 ;
localparam CALC = 3 ;

logic [15:0] slope1_w, slope1_r, slope2_w, slope2_r ;
logic [1:0] state_w, state_r ;
logic slope_start, finish ;

wire [0:25599] full_fp ;
wire [10:0] slope_addr ;
wire [15:0] slope_data, slope_result ;
int feat_score,feat_score_w,feat_score_r ;
wire control, slope_fin, feat_fin ;

assign full_fp = i_full_fp ;
assign slope_data = (state_w<=FIRST_FP)? full_fp[16*slope_addr+:16] : i_sram_data ;
assign o_finish = finish ;
assign o_match = (signed'(slope1_r-slope2_r)<400 && signed'(slope1_r-slope2_r)>-400)? feat_score_r : 0 ;

Core_Feat f1(
    .i_clk(i_clk),
    .i_start(i_start),
    .i_sram_data(i_sram_data),
    .i_begin_address(i_begin_address),
    .i_full_fp(i_full_fp),
    .o_sram_address(o_sram_address),
    .o_score(feat_score),                                          // format : 10000*IoU
    .o_control_start(control),
    .o_finish(feat_fin)
);

Core_Slope s1(
    .i_clk(i_clk),
    .i_start(slope_start),
    .i_data(slope_data),
    .o_sram_address(slope_addr),
    .o_slope(slope_result),                                  // format : slope = 1.327, o_slope = 1327
    .o_finish(slope_fin)
);


always_comb begin
    state_w = state_r ;
    slope_start = 0 ;
    finish = 0 ;
    feat_score_w = feat_score_r ;
    slope1_w = slope1_r ; slope2_w = slope2_r ;

    case(state_r)
        IDLE : begin
            if(i_start) begin
                slope_start = 1 ;
                state_w = FIRST_FP ;
            end
        end
        FIRST_FP : begin
            slope_start = 0 ;
            if(slope_fin) begin
                slope1_w = slope_result ;
            end
            if(control) begin
                slope_start = 1 ;
                state_w = SECON_FP ;
            end
        end
        SECON_FP : begin
            slope_start = 0 ;
            if(slope_fin) begin
                slope2_w = slope_result ;
            end
            if(feat_fin) begin
                feat_score_w = feat_score ;
                state_w = CALC ;
            end
        end
        CALC : begin
            finish = 1 ;
            state_w = IDLE ;
        end
        default : begin 
            state_w = IDLE ;
        end
    endcase
end

always_ff @(posedge i_clk) begin
    feat_score_r <= feat_score_w ;
    slope1_r <= slope1_w ;
    slope2_r <= slope2_w ;
    state_r <= state_w ;
end


endmodule