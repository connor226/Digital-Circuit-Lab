module database(
    input  i_FL_RY,
    input  i_num,
    output [22:0] o_FL_ADDR,
    inout  [7:0]  o_FL_DATA,
    output [159:0][159:0][7:0] o_data,
    output o_data_rd
);
// assign o_FL_CE_N  = 1'b0;
// assign o_FL_OE_N  = 1'b0;
// assign o_FL_RST_N = 1'b1;
localparam data_length = 23'd25600;


endmodule