module Top4 (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out,
	output [15:0] o_chosen_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first

	
	reg [1:0] state_r;			//  0->idle 1->run 2->call prophet 3->wait for prophet
	reg [25:0]counter_r;   		// counter>period counter<=0
	reg [25:0]period_r;	 		// period increase after counter<=0
	reg [15:0]o_random_out_r;
	reg [15:0]time_seed_r; 		// keep running
	reg [15:0]o_chosen_r;
	reg [15:0]chosen_num;
	reg start_prophet_r;			// changed when entering state 2
	
	logic [1:0] state_w;			//  0->idle 1->run 2->call prophet 3->wait for prophet
	logic [25:0]counter_w;   		// counter>period counter<=0
	logic [25:0]period_w;	 		// period increase after counter<=0
	logic [15:0]o_random_out_w;
	logic [15:0]time_seed_w; 		// keep running
	logic [15:0]chosen_num_w;
	logic [15:0]o_chosen_rw;
	logic start_prophet_w;		

	wire feedback;
	wire finish_prophet_w;
	wire [15:0]seed_prophet_w;
	
	assign feedback = o_random_out_r[15] ^ o_random_out_r[13] ^ o_random_out_r[12] ^ o_random_out_r[10] ;
	assign o_random_out = {o_random_out_r[2],o_random_out_r[6],o_random_out_r[3],o_random_out_r[5]} ; //time_seed_r[15:12] ;
	assign o_chosen_out = o_chosen_r;

	parameter initial_clk_period = 5_000000;
	parameter clk_period_step = 1_000000;
	parameter max_clk_period = 25_000000;

	prophet p1( .i_clk(i_clk), .i_rst_n(i_rst_n), .i_start(start_prophet_w), .i_seed(time_seed_r), 
				 .o_new_seed(seed_prophet_w), .o_finished(finish_prophet_w), .o_chosen_out(chosen_num_w) );


	// combinatorial logic
	always_comb begin
		
		state_w = state_r ;
		counter_w = counter_r ;
		period_w = period_r ;
		o_random_out_w = o_random_out_r ;
		time_seed_w = time_seed_r + 1;
		o_chosen_rw = o_chosen_r;
		start_prophet_w = start_prophet_r ;
	
		case (state_r) 
			0 : begin
				if(i_start) begin
					counter_w 	= 0 ;
					period_w 	= initial_clk_period ;
					state_w		= 2 ;
					o_chosen_rw = chosen_num;
				end
			end

			1 : begin
				if(i_start) begin
					counter_w 	= 0 ;
					period_w 	= initial_clk_period ;
					state_w		= 2 ;
					o_chosen_rw = chosen_num;
				end
				else if (counter_r<period_r)
					counter_w	= counter_r + 1 ;
				else begin
					counter_w 		= 0 ;
					period_w		= period_r + clk_period_step ;
					o_random_out_w	= {o_random_out_r[14:0],feedback} ;

					if (period_r >= max_clk_period) begin
						state_w 	= 0 ;
						//chosen_w[{o_random_out_w[2],o_random_out_w[6],o_random_out_w[3],o_random_out_w[5]}] = 1 ;
						o_chosen_rw = chosen_num;
					end
				end
			end

			2 : begin
				start_prophet_w = 1 ;
				state_w			= 3 ;
			end

			3 : begin
				start_prophet_w	= 0 ;
				if (finish_prophet_w) begin
					o_random_out_w	= seed_prophet_w ;
					state_w			= 1 ;
				end
			end

			default: begin
				state_w 		= 0;
				counter_w 		= 0;
				period_w 		= 0;
				o_random_out_w 	= 0;
				time_seed_w 	= 0;
				start_prophet_w	= 0;
				o_chosen_r 		= 0;
			end

		endcase

	end

	// sequential logic
	always_ff @( posedge i_clk or negedge i_rst_n ) begin
		if (!i_rst_n) begin
			o_random_out_r	<= 0 ;
			state_r			<= 0 ;
			chosen_num <= 0;
			o_chosen_r <= 0;
		end
		else begin
			state_r 		<= state_w;
			counter_r 		<= counter_w;
			period_r 		<= period_w;
			o_random_out_r 	<= o_random_out_w;
			time_seed_r 	<= time_seed_w;
			chosen_num <= chosen_num_w;
			o_chosen_r 		<= o_chosen_rw;
		end
	
	end



endmodule


module prophet (
	input  i_clk,
	input  i_rst_n,
	input  i_start,
	input  [15:0]i_seed,
	//input  [15:0]chosen,
	output [15:0]o_new_seed, 
	output [15:0] o_chosen_out,
	output o_finished
);

	//reg finished_r;
	reg [1:0]  state_r;  // 0->idle    1->for loop    2->while loop
	reg [4:0]  counter_r; // 20 times for loop
	reg [15:0] res_r;
	reg [15:0] seed_r;
	reg [15:0] chosen_r ;

	logic finished_w;
	logic [1:0]  state_w;  // 0->idle    1->for loop    2->while loop
	logic [4:0]  counter_w; // 20 times for loop
	logic [15:0] res_w;
	logic [15:0] seed_w;
	logic [15:0] chosen_w ;
	
	wire feedback_res;
	wire feedback_seed;
	wire [3:0]value;

	assign feedback_res  = res_r[15]  ^ res_r[13]  ^ res_r[12]  ^ res_r[10]  ;
	assign feedback_seed = seed_r[15] ^ seed_r[13] ^ seed_r[12] ^ seed_r[10] ;
	assign value = {res_r[2],res_r[6],res_r[3],res_r[5]} ;
	assign o_finished = finished_w ;
	assign o_new_seed = seed_r ; //{12'b000000000000,value} ;	// peeping
	
	initial begin
		chosen_r <= 0 ;
	end
	

	always_comb begin
		finished_w 	= 0 ;
		seed_w		= seed_r ;
		res_w 		= res_r ;
		counter_w 	= counter_r ;
		state_w		= state_r ;
		chosen_w		= chosen_r ;
		o_chosen_out = chosen_r;
		
		case (state_r)
			0 : begin
				if (i_start) begin
					finished_w 	= 0 ;
					seed_w		= i_seed ;
					res_w 		= i_seed ;
					counter_w 	= 0 ;
					state_w		= 1 ;
				end
			end

			1 : begin
				
				if (counter_r<21) begin
					counter_w 	= counter_r + 1 ;
					res_w  		= {res_r[14:0], feedback_res} ;
				end
				else 
					state_w = 2 ;
			end

			2 : begin
				if(chosen_r[value]) begin
					res_w	= {res_r[14:0], feedback_res}  ;
					seed_w	= {seed_r[14:0],feedback_seed} ;
				end
				else begin
					state_w		= 0 ;
					finished_w 	= 1 ;
					chosen_w[value] = 1 ;
					
				end
			end

			default : begin
				state_w = 0 ;
				chosen_w = 0 ;
			end
		endcase
	end

	always_ff @( posedge i_clk or negedge i_rst_n ) begin 
		if(!i_rst_n) begin
			state_r		<= 0 ;
			counter_r	<= 0 ;
			res_r 		<= 0 ;
			seed_r		<= 0 ;
			chosen_r 	<= 0 ;
		end
		else begin
			state_r		<= state_w ;
			counter_r	<= counter_w ;
			res_r 		<= res_w ;
			seed_r		<= seed_w ;
			chosen_r 	<= chosen_w ;
		end
	end




endmodule