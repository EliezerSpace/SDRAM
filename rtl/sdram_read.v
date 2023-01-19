
module sdram_read(
	input				rd_clk			,	
	input				rd_rst_n		,
	input				rd_en			,
	input				init_end		,
	input		[23:0]	rd_addr			,
	input		[15:0]	rd_data			,
	input		[9:0]	rd_burst_len	,
	
	output				rd_end			,
	output				rd_ack			,
	output	reg	[3:0]	rd_sdram_cmd	,
	output	reg	[12:0]	rd_sdram_addr	,
	output	reg	[1:0]	rd_sdram_bank	,
	output		[15:0]	rd_sdram_data	
);
//parameter timing
parameter	TRCD = 10'd2,
			TCL	 = 10'd3,
			TRP	 = 10'd4;
//state define
parameter	RD_IDLE	    = 4'd0,
			RD_ACT	    = 4'd1,
			RD_TRCD	    = 4'd2,
			RD_RD_CMD	= 4'd3,
			RD_CL	    = 4'd4,
			RD_DATA	    = 4'd5,
			RD_PRE	    = 4'd6,
			RD_TRP	    = 4'd7,
			RD_END	    = 4'd8;
//cmd define
parameter	NOP 		= 4'b0111,
			ACTIVE      = 4'b0011,
			READ        = 4'b0101,
			BURST_STOP  = 4'b0110,
			PRECHARGE   = 4'b0010;
			
			
reg [3:0] state_cur;
reg [3:0] state_next;

reg [9:0]	cnt_fsm;
reg 		cnt_fsm_rst;
reg [15:0]	rd_data_reg;


wire	trcd_end_flag	;
wire	cl_end_flag		;
wire	tread_end_flag	;
wire	trp_end_flag	;
wire	rdburst_end_flag;

assign trcd_end_flag	=	(state_cur == RD_TRCD && cnt_fsm == TRCD - 1'b1) ? 1'b1 : 1'b0; 
assign cl_end_flag		=   (state_cur == RD_CL && cnt_fsm == TCL - 1'b1) ? 1'b1 : 1'b0; 
assign tread_end_flag	=   (state_cur == RD_DATA && cnt_fsm == rd_burst_len) ? 1'b1 : 1'b0; 
assign trp_end_flag	    =   (state_cur == RD_TRP && cnt_fsm == TRP - 1'b1) ? 1'b1 : 1'b0; 
assign rdburst_end_flag = 	(state_cur == RD_DATA && cnt_fsm == rd_burst_len - 4) ? 1'b1 : 1'b0; //?

assign rd_end = (state_cur == RD_END) ? 1'b1 : 1'b0;
assign rd_sdram_data = rd_ack ? rd_data_reg : 16'd0;

assign rd_ack = ((state_cur == RD_DATA) && (cnt_fsm >= 10'd1) && (cnt_fsm < rd_burst_len + 1'b1));


always@(posedge rd_clk or negedge rd_rst_n)begin
	if(~rd_rst_n)
		rd_data_reg <= 16'd0;
	else
		rd_data_reg <= rd_data;
end
always@(*)begin
	case(state_cur)
		RD_TRCD : 	cnt_fsm_rst = trcd_end_flag ? 1'b1 : 1'b0;
		RD_CL 	: 	cnt_fsm_rst = cl_end_flag ? 1'b1 : 1'b0;
		RD_DATA : 	cnt_fsm_rst = tread_end_flag ? 1'b1 : 1'b0;
		RD_TRP 	: 	cnt_fsm_rst = trp_end_flag ? 1'b1 : 1'b0;
		default	:	cnt_fsm_rst = 1'b1;
	endcase
end
always@(posedge rd_clk or negedge rd_rst_n)begin
	if(~rd_rst_n)begin
		cnt_fsm <= 10'd0;
	end
	else begin
		if(cnt_fsm_rst)
			cnt_fsm <= 10'd0;
		else
			cnt_fsm <= cnt_fsm + 1'b1;
	end
end

//three stages state machine
always@(posedge rd_clk or negedge rd_rst_n)begin
	if(~rd_rst_n)
		state_cur <= RD_IDLE;
	else
		state_cur <= state_next;
end
always@(*)begin
	case(state_cur)
		RD_IDLE	  	:	state_next = (rd_en & init_end) ? RD_ACT : RD_IDLE;
		RD_ACT	  	:  	state_next = RD_TRCD;
		RD_TRCD	  	:   state_next = trcd_end_flag ? RD_RD_CMD : RD_TRCD;
		RD_RD_CMD	:	state_next = RD_CL;
		RD_CL	  	:   state_next = cl_end_flag ? RD_DATA : RD_CL;
		RD_DATA	  	:  	state_next = tread_end_flag ? RD_PRE : RD_DATA;
		RD_PRE	  	:   state_next = RD_TRP;
		RD_TRP	  	:  	state_next = trp_end_flag ? RD_END : RD_TRP;
		RD_END	  	:  	state_next = RD_IDLE;
		default		:	state_next = RD_IDLE;
	endcase	
end
always@(posedge rd_clk or negedge rd_rst_n)begin
	if(~rd_rst_n)begin
		rd_sdram_cmd	<=	NOP;
		rd_sdram_addr	<=	13'h1fff;
		rd_sdram_bank	<=	2'b11;
	end
	else begin
		case(state_cur)
			RD_IDLE	  	:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end
		    RD_ACT	  	:begin
				rd_sdram_cmd	<=	ACTIVE;
				rd_sdram_addr	<=	rd_addr[21:9];
				rd_sdram_bank	<=	rd_addr[23:22];
			end  
		    RD_TRCD	  	:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end  
		    RD_RD_CMD	:begin
				rd_sdram_cmd	<=	READ;
			    rd_sdram_addr	<=	{4'd0,rd_addr[8:0]};
			    rd_sdram_bank	<=	rd_addr[23:22];
			end	
		    RD_CL	  	:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end  
		    RD_DATA	  	:begin
				rd_sdram_addr	<=	13'h1fff;
				rd_sdram_bank	<=	2'b11;
				if(rdburst_end_flag)
					rd_sdram_cmd	<=	BURST_STOP;
				else
					rd_sdram_cmd	<=	NOP;
			end  
		    RD_PRE	  	:begin
				rd_sdram_cmd	<=	PRECHARGE;
			    rd_sdram_addr	<=	13'h0400;
			    rd_sdram_bank	<=	rd_addr[23:22];
			end  
		    RD_TRP	  	:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end  
		    RD_END	  	:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end  
			default		:begin
				rd_sdram_cmd	<=	NOP;
			    rd_sdram_addr	<=	13'h1fff;
			    rd_sdram_bank	<=	2'b11;
			end
		endcase
	end
end
endmodule