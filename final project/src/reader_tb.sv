module testbench;

    reg tx ;
    reg clk;
    wire [7:0] o;
    wire finish ;

    //adder test_adder(.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    SFM_reader r1(
        .i_clk(clk),
        .i_tx_from_sfm(tx),
        .o_data(o),
        .o_finish(finish)
    );

    always #5 i_clk = ~ i_clk;

    initial begin
        $fsdbDumpfile("print.fsdb");
        $fsdbDumpvars;
        clk = 0;
        tx = 1 ;
        # 100

        tx = 0 ; #10

        tx = 1 ; #10
        tx = 1 ; #10
        tx = 0 ; #10
        tx = 1 ; #10
        tx = 0 ; #10
        tx = 0 ; #10
        tx = 1 ; #10
        tx = 1 ; #10


        tx = 1 ; 
        # 1500 $finish; 
    end

endmodule
