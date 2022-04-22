`timescale 1ns/100ps

module tb;
    logic clk, rst_n, start, pause, stop, fast, slow0, slow1, lrck;
    logic [2:0] speed;
    logic [15:0] sdat, dat;
    logic [19:0] addr;
    initial clk = 0;
    always #5 clk = ~clk;

    AudDsp DUT(
        .i_rst_n(rst_n),
    	.i_clk(clk),
    	.i_start(start),
    	.i_pause(pause),
    	.i_stop(stop),
    	.i_speed(speed),
    	.i_fast(fast),
    	.i_slow_0(slow0), // constant interpolation
    	.i_slow_1(slow1), // linear interpolation
    	.i_daclrck(lrck),
    	.i_sram_data(sdat),
    	.o_dac_data(dat),
    	.o_sram_addr(addr)
    );

    initial begin
        $fsdbDumpfile("AudDsp.fsdb");
		$fsdbDumpvars;
        rst_n = 1;
        en = 0;
        slow0 = 0;
        slow1 = 0;
        pause = 0;
        stop = 0;
        # 50
        rst_n = 0;
        # 10
        rst_n = 1;
        start = 1;
        # 20
        fast = 1;
        speed = 0;
        dat = 16'b1001011011000011;
        # 540_000
        dat = 16'b0101101001101001;
    end

    always @(addr) begin
        sdat
    end
    
    initial begin
        for(int i = 0; i < 10_000; i++) begin
            lrck = 0;
            for(int j = 0; j < 21; j ++) begin
                @(posedge clk) ;
            end
            lrck = 1;
            for(int j = 0; j < 21; j++) begin
                @(posedge clk) ;
            end
        end
    end

endmodule
