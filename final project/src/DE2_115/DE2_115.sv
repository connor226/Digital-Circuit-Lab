module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [7:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);
/*
Debounce deb0(
	.i_in(KEY[0]),
	.i_rst_n(KEY[1]),
	.i_clk(CLOCK_50),
	.o_neg(keydown)
);
*/
SevenHexDecoder seven_dec0(
	.i_hex(shd0[7:4]),
	.o_seven_ten(HEX7),
	.o_seven_one(HEX6)
);

SevenHexDecoder seven_dec1(
	.i_hex(shd0[3:0]),
	.o_seven_ten(HEX5),
	.o_seven_one(HEX4)
);

SevenHexDecoder seven_dec2(
	.i_hex(shd1[7:4]),
	.o_seven_ten(HEX3),
	.o_seven_one(HEX2)
);

SevenHexDecoder seven_dec3(
	.i_hex(shd1[3:0]),
	.o_seven_ten(HEX1),
	.o_seven_one(HEX0)
);

clock clk1(
	.clk_clk(CLOCK_50),          // clk.clk
	.clk_25m_clk(clk_116500), // clk_116500.clk
	.clk_116800_clk(clk_116800), // clk_116800.clk
	.clk_12m_clk(clk_12m),       // clk_12m.clk
	.reset_reset_n(KEY[0])       // reset.reset_n
);

logic clk_116500, clk_116800, clk_12m;
// debug logic
logic [7:0] shd0, shd1, debug0;
logic [1:0] debug3;
logic [17:0] debug2;

assign GPIO[24] = GPIO[27] ? 1'b1 : 1'b0;
assign GPIO[26] = 1'bz;
assign GPIO[27] = 1'bz;
assign LEDG[0] = GPIO[26] ? 1'b0 : 1'b1;
assign LEDG[1] = GPIO[27] ? 1'b1 : 1'b0;
assign LEDG[3:2] = debug3;
assign LEDR[17:0] = debug2;

Top top(
	.i_rst_n(KEY[0]),
	.i_clk(clk_12m),
	.i_mode(SW[17]), // mode 0: register, mode 1: compare
	.i_baud(clk_116800), // 115200 Hz
	.i_start(!KEY[1]),
	.i_rx_from_sfm(GPIO[26]),
	.o_tx_to_sfm(GPIO[25]),

    // SRAM
	.o_SRAM_ADDR(SRAM_ADDR),
	.io_SRAM_DQ(SRAM_DQ),
	.o_SRAM_WE_N(SRAM_WE_N),
	.o_SRAM_CE_N(SRAM_CE_N),
	.o_SRAM_OE_N(SRAM_OE_N),
	.o_SRAM_LB_N(SRAM_LB_N),
	.o_SRAM_UB_N(SRAM_UB_N),
	
	// sevenHexDecoder
	.o_shd0(shd0),
	.o_shd1(shd1),

   // debug
	.o_debug0(debug0),
	.o_debug1(debug3),
	.o_debug2(debug2),
	.o_debug3(LEDG[7:5])
);

endmodule
