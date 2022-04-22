module AudDSP0(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,           
	input [2:0] i_speed,    // 1~8
	input i_fast,           // fast play
	input i_slow_0,         // constant interpolation
	input i_slow_1,         // linear interpolation
	input i_daclrck,
	input signed [15:0] i_sram_data,      // data from SRAM
	input  [19:0] max_addr,
	output [15:0] o_dac_data,
	output [19:0] o_sram_addr      // choose SRAM address to read
);

localparam idle  = 0 ;
localparam fast  = 1 ;  // including 1x to 8x
localparam slow0 = 2 ;
localparam slow1 = 3 ;
localparam paus  = 4 ;
localparam waits = 5 ;
// localparam max_addr = 20'b11111111111111111111 ;


logic [2:0]  state_r, state_w ;
logic signed [15:0] data_r, data_w, pre_SRAM_r, pre_SRAM_w ;
logic [19:0] address_r, address_w ;
logic [2:0] ctr_slow_r, ctr_slow_w ;
logic last_lr_r ;

assign o_dac_data = data_r ;
assign o_sram_addr = address_w ;


task FastPlay;
    data_w    = i_sram_data ;
    address_w = address_w + i_speed + 1 ; // i_speed = 2 -> 3x  thus address += 2 + 1
	 state_w = waits ;
	 
	 if(address_w >= max_addr - i_speed - 1) begin
	     address_w = max_addr ;
	 end
	 
endtask

task SlowPlay0;
    data_w = i_sram_data ;
    
    if(ctr_slow_w == i_speed) begin
        ctr_slow_w = 0 ;
        address_w = address_w + 1 ;
	 end
    else begin
        ctr_slow_w = ctr_slow_w + 1 ;
    end
	 
	 state_w = waits ;
endtask

task SlowPlay1;
    data_w = (signed'(ctr_slow_w)*i_sram_data + (signed'(i_speed)-signed'(ctr_slow_w)+1)*pre_SRAM_w) / signed'(i_speed+1);  // for 3x , i_speed = 2

    if(ctr_slow_w == i_speed) begin
        ctr_slow_w = 0 ;
		  pre_SRAM_w = signed'(i_sram_data) ;
        address_w  = address_w + 1 ;
    end
    else begin
        ctr_slow_w = ctr_slow_w + 1 ;
    end
	 
	 state_w = waits ;
endtask

task check_finish;
    if(address_w >= max_addr) begin // all data played
        state_w = idle ;    
    end
endtask


always_comb begin
    state_w     = state_r ;
    data_w      = data_r ;
    pre_SRAM_w  = pre_SRAM_r ;
    address_w   = address_r ;
    ctr_slow_w  = ctr_slow_r ;
    
    case(state_r)
        idle : begin
            if(i_start) begin
                address_w   = 0 ;
                ctr_slow_w  = 0 ;
                pre_SRAM_w  = 0 ;
            end
        end

        fast : begin
            FastPlay() ;  
            check_finish() ;          
        end

        slow0 : begin
            SlowPlay0();   
            check_finish() ;           
        end

        slow1 : begin
            SlowPlay1();
            check_finish() ;  
        end

        paus : begin
        
        end

        waits : begin
            if((!last_lr_r) && i_daclrck) begin
                if(i_fast)          state_w = fast ;
                else if(i_slow_0)   state_w = slow0 ;
                else if(i_slow_1)   state_w = slow1 ;
                else                state_w = fast ;
            end
        end


    endcase


    // set state_w 
    if(i_start) begin                             // start playing
        if(i_fast)          state_w = fast ;
        else if(i_slow_0)   state_w = slow0 ;
        else if(i_slow_1)   state_w = slow1 ;
        else                state_w = fast ;
    end
    else if(i_pause) begin                        // pause
        state_w = paus ;
    end


end



always_ff @(negedge i_rst_n or negedge i_clk or posedge i_stop) begin 
    if((!i_rst_n) || i_stop) begin
        state_r     <= idle ;
        data_r      <= 0 ;
        pre_SRAM_r  <= 0 ;
        address_r   <= 0 ;
        ctr_slow_r  <= 0 ;
        last_lr_r   <= i_daclrck ;
    end
    else begin
        state_r     <= state_w ;
        data_r      <= data_w ;
        pre_SRAM_r  <= pre_SRAM_w ;
        address_r   <= address_w ;
        ctr_slow_r  <= ctr_slow_w ;
        last_lr_r   <= i_daclrck ;
    end
end











endmodule