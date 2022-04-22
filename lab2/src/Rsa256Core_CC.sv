//Top module
module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm

reg [1:0]   state_r;// 00->idle 01->prep 10->mont 11->calc
reg [8:0]   ctr_r;
reg         start_mont_r;
reg [255:0] m_r;
reg [255:0] t_r;
reg [255:0] a_r, aprime_r;


logic [1:0]     state_w;// 00->idle 01->prep 11->mont 10->calc
logic [8:0]     ctr_w;
logic           start_mont_w;
logic [255:0]   m_w;
logic [255:0]   t_w;
logic [255:0]   a_w, aprime_w;
logic [255:0]   pro_output_w;
logic [255:0]   mont_output_w, mont_output_wprime;
logic           pro_finished_w;
logic           mont_finished_w, mont_finished_wprime;
logic           o_finish_w ;


assign o_finished = o_finish_w ;
assign o_a_pow_d=m_r;

Productor _pro( .i_clk(i_clk),.i_start(i_start),.i_rst_n(!i_rst),
                .i_N(i_n),.i_b(i_a),
                .o_finish(pro_finished_w),.o_m(pro_output_w));

Montgomery _mont(   .i_clk(i_clk),.i_start(start_mont_r),.i_rst_n(!i_rst),
                    .i_N(i_n),.i_a(a_w),.i_b(t_w),
                    .o_m(mont_output_w),.o_finish(mont_finished_w));

Montgomery _m0nt(   .i_clk(i_clk),.i_start(start_mont_r),.i_rst_n(!i_rst),
                    .i_N(i_n),.i_a(aprime_w),.i_b(t_w),
                    .o_m(mont_output_wprime),.o_finish(mont_finished_wprime));

//combinational logic
always_comb begin	
    o_finish_w      = 0 ;
	state_w         = state_r;
    ctr_w           = ctr_r;
    start_mont_w    = start_mont_r;
    m_w             = m_r;
    t_w             = t_r;
    a_w             = a_r;
    aprime_w        = aprime_r;

	case (state_r)
		//idle
		2'b00: begin
			if(i_start)begin
				state_w = 2'b01;//go prep
                ctr_w = 0 ;
			end
		end
		//prep
		2'b01: begin	
			if(pro_finished_w)begin
                t_w = pro_output_w ;
                m_w = 1 ;
				state_w=2'b10;//go mont
                a_w = t_w;
                if(i_d[0])  aprime_w = m_w;
                start_mont_w = 1 ;
			end

			else begin
				state_w=2'b01;//stay prep
            end
				
		end
		//mont
		2'b10: begin
            //
            start_mont_w = 0;
            if(mont_finished_w) begin
                state_w=2'b11;
                ctr_w = ctr_r + 1 ;
                if (i_d[ctr_r]) 
                    m_w = mont_output_wprime ; 
                t_w = mont_output_w ;
            end
            else 
                state_w=2'b10 ;

		end
		//calc
		2'b11: begin
            //
            if(!ctr_r[8]) begin  // ctr_r < 256
                state_w=2'b10 ;
                start_mont_w = 1 ;
                if(i_d[ctr_r])
                    aprime_w=m_r;
                a_w=t_r;
            end
            else begin // finish 256 times
                state_w=2'b00;//go idle
                o_finish_w = 1 ;
            end
		end

		default begin
			//default wire
            o_finish_w      = 0;
            state_w         = 0;
            ctr_w           = 0;
            start_mont_w    = 0;
            m_w             = 1;
            t_w             = 0;
            a_w             = 1;
            aprime_w        = 0;
        end
    endcase
end
			
		
//sequential logic
always_ff @( posedge i_clk or negedge i_rst ) begin
	if (i_rst) begin
		state_r <=0;
        start_mont_r<=0;
        t_r<=0;
        m_r<=0;
        ctr_r<=0;
        a_r<=0;
        aprime_r<=0;
	end
	
	else begin
		state_r <=state_w;
        start_mont_r<=start_mont_w;
        t_r<=t_w;
        m_r<=m_w;
        ctr_r<=ctr_w;
        a_r<=a_w;
        aprime_r<=aprime_w;
	end
end

endmodule

module Productor (
    input   i_clk,
    input   i_start,
    input   i_rst_n,
    input   [255:0] i_N,  // length of bits is 255 = 2^8 -> need a 8-bit counter
    input   [255:0] i_b,
    output  [255:0] o_m,
    output  o_finish
);

    reg state_r;
    reg finish_r;
    reg [256:0] m_r;
    reg [256:0] t_r;
    reg [  8:0] counter_r;

    logic state_w;
    logic finish_w;
    logic [256:0] m_w;
    logic [256:0] t_w;
    logic [  8:0] counter_w;

    assign o_finish = finish_w ;
    assign o_m      = m_w[255:0] ;
    

    // combinational logic
    always_comb begin
        // default value
        state_w     = state_r ;
        m_w         = m_r ;
        t_w         = t_r ;
        counter_w   = counter_r ;
        finish_w    = finish_r ;

        // state machine
        case(state_r)
            0 : begin
                if(i_start) begin
                    state_w     = 1 ;
                    m_w         = 0 ;
                    t_w         = {1'b0, i_b} ;
                    counter_w   = 0 ;
                    finish_w    = 0 ;
                end            
            end

            1: begin
                if(t_r+t_r > i_N)
                    t_w = t_r + t_r - i_N ;
                else
                    t_w = t_r + t_r ;
                // counter == 256 final round is done
                if(counter_r == 256) begin
                    if(m_r+t_r >= i_N) begin
                        m_w = m_r + t_r - i_N ;
                    end
                    else begin
                        m_w = m_r + t_r ;
                    end
                    state_w  = 0 ;
                    finish_w = 1 ;
                end
                counter_w = counter_r + 1 ;
            
            end

            default begin
                state_w     = 0 ;
                m_w         = 0 ;
                t_w         = 0 ;
                counter_w   = 0 ;
                finish_w    = 0 ;
            end
        endcase
        
        
    end

    // sequential logic
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            state_r     <= 0;
            m_r         <= 0;
            t_r         <= 0;
            counter_r   <= 0;
            finish_r    <= 0;
        end
        else begin
            state_r     <= state_w;
            m_r         <= m_w;
            t_r         <= t_w;
            counter_r   <= counter_w;
            finish_r    <= finish_w;
        end        
    end
    
endmodule


module Montgomery (
    input   i_clk,
    input   i_start,
    input   i_rst_n,
    input   [255:0] i_N,  // length of bits is 256 = 2^8 -> need a 8-bit counter
    input   [255:0] i_a,
    input   [255:0] i_b,
    output  [255:0] o_m,
    output  o_finish
);

    reg state_r;
    reg finish_r;
    reg [256:0] m_r;
    reg [  7:0] counter_r;

    logic state_w;
    logic finish_w;
    logic [256:0] m_w;
    logic [  7:0] counter_w;
    logic [257:0] tmp1;
    logic [256:0] tmp2;

    assign o_finish = finish_r;
    assign o_m      = m_r[255:0] ;
    

    // combinational logic
    always_comb begin
        // default value
        state_w     = state_r ;
        m_w         = m_r ;
        counter_w   = counter_r ;
        finish_w    = 0 ;
        tmp1        = m_r ;
        tmp2        = m_r ;

        // state machine
        case(state_r)
            0 : begin
                m_w         = 0 ;
                counter_w   = 0 ;
                finish_w    = 0 ;
                tmp1        = 0 ;
                tmp2        = 0 ;
                if(i_start) begin
                    state_w     = 1 ;
                end            
            end

            1: begin
                if(i_a[counter_r]) 
                    tmp1 = m_r + i_b + ((m_r[0]^i_b[0])? i_N:0) ;
                else 
                    tmp1 = m_r + ((m_r[0])? i_N:0) ;
                tmp2 = tmp1 >> 1 ;
                m_w = tmp2 ;
                // counter == 255 final round is done
                if(&counter_r) begin
                    m_w = tmp2 - (tmp2>=i_N? i_N : 0) ;
                    state_w  = 0 ;
                    finish_w = 1 ;
                end
                else
                    counter_w = counter_r + 1 ;
            end

            default begin
                state_w     = 0 ;
                m_w         = 0 ;
                counter_w   = 0 ;
                finish_w    = 0 ;
                tmp1        = 0 ;
                tmp2        = 0 ;
            end
        endcase
        
        
    end

    // sequential logic
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            state_r     <= 0;
            m_r         <= 0;
            counter_r   <= 0;
	        finish_r    <= 0;
        end
        else begin
            state_r     <= state_w;
            m_r         <= m_w;
            counter_r   <= counter_w;
	        finish_r    <= finish_w;
        end        
    end
    
endmodule
