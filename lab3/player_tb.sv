`timescale 1ns/100ps

module tb;
    logic rst_n, bclk, daclrck, en, datout;
    logic [15:0] dat;
    
    initial bclk = 0;
    always #5 bclk = ~bclk;

    AudPlayer DUT(
        .i_rst_n(rst_n),
        .i_bclk(bclk),
        .i_daclrck(daclrck),
        .i_en(en),
        .i_dac_data(dat),
        .o_aud_dacdat(datout)
    );

    initial begin
        $fsdbDumpfile("AudPlayer.fsdb");
		$fsdbDumpvars;
        rst_n = 1;
        en = 0;
        # 50
        rst_n = 0;
        # 10
        rst_n = 1;
        # 20
        en = 1;
        dat = 16'b1001011011000011;
        # 540
        dat = 16'b0101101001101001;
    end

    initial begin
        for(int i = 0; i < 100; i++) begin
            daclrck = 0;
            for(int j = 0; j < 21; j++) begin
                @(negedge bclk);
            end
            daclrck = 1;
            for(int j = 0; j < 21; j++) begin
                @(negedge bclk);
            end
        end
        $finish;
    end
endmodule
