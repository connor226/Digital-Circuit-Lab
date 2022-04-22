`timescale 1ns/100ps

module tb;
    logic clk, rst_n, lrc, start, stop, pause, data;
    logic [19:0] address;
    logic [15:0] o_data;

    initial clk = 0;
    always #5 clk = ~clk;

    AudRecorder DUT(
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_start(start),
        .i_stop(stop),
        .i_pause(pause),
        .i_lrc(lrc),
        .i_data(data),
        .o_address(address),
        .o_data(o_data)
    );

    initial begin
        $fsdbDumpfile("AudRecorder.fsdb");
		$fsdbDumpvars;
        rst_n = 1;
        lrc = 1;
        start = 0;
        stop = 0;
        pause = 0;
        data = 0;
        # 50
        rst_n = 0;
        # 10
        rst_n = 1;
        start = 1;
        # 10
        start = 0;
        # 200_000
        pause = 1;
        start = 0;
        # 10
        pause = 0;
        # 1_000
        start = 1;
        # 10
        start = 0;
        # 100_000
        stop = 1;
        # 10
        stop = 0;
    end

    initial begin
        for(int i = 0; i < 50_000; i++) begin
            lrc = 0;
            for(int j = 0; j < 21; j++) begin
                @(negedge clk) data = ~data;
            end
            lrc = 1;
            for(int j = 0; j < 21; j++) begin
                @(negedge clk) data = ~data;
            end
        end
        $finish;
    end

endmodule
