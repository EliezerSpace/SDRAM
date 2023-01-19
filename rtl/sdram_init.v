module sdram_init(
	input				init_clk	,//init clock
	input				init_rst_n	,//init reset negedge valid
	
	output	reg	[3:0]	init_cmd	,//command
	output 	reg [12:0]	init_addr	,//address
	output	reg	[1:0]	init_bank	,//bank
	output	reg			init_end	 //init end valid signal
);
localparam T_WAIT = 15'd20_000;//100M 10ns counter maximum
localparam AR_MAX = 4'd8;		//auto refresh times
//time parameter to wait
localparam 	TRP = 3'd2,		//precharge cycle
			TRFC = 3'd7,	//auto refresh cycle
			TMRD = 3'd3;	//mode register set cycle
localparam	PRECHARGE 	= 4'b0010,	//precharge
			AT_REF		= 4'b0001,	//auto refresh
			NOP 		= 4'b0111,	//nop
			MREG_SET 	= 4'b0000;	//mode register set
//state code (gray)
localparam 	INIT_WAIT	=	3'b000,//power on and wait state
			INIT_PRE    =	3'b001,//send precharge cmd state
			INIT_TRP    =	3'b011,//Trp time state
			INIT_AR     =	3'b010,//send auto refresh cmd state
			INIT_TRFC   =	3'b110,//Trfc time state
			INIT_MRS    =	3'b111,//send mode register set cmd state
			INIT_TMRD   =	3'b101,//Tmrd time state
			INIT_END    =	3'b100;//init finish state
			
			
reg [2:0] state_cur;
reg [2:0] state_next;

wire	wait_end_flag;
wire 	trp_end_flag;
wire 	trfc_end_flag;
wire 	tmrd_end_flag;


reg cnt_fsm_rst;//cnt_fsm reset
reg [14:0] cnt_wait;//init wait time counter
reg [3:0]	cnt_fsm;//the clock cycle counter
reg [3:0]	cnt_ar;//ar times counter

assign wait_end_flag = (cnt_wait == T_WAIT - 1'b1) ? 1'b1 : 1'b0;
assign trp_end_flag = (state_cur == INIT_TRP && cnt_fsm == TRP - 1'b1) ? 1'b1 : 1'b0;
assign trfc_end_flag = (state_cur == INIT_TRFC && cnt_fsm == TRFC - 1'b1) ? 1'b1 : 1'b0;
assign tmrd_end_flag = (state_cur == INIT_TMRD && cnt_fsm == TMRD - 1'b1) ? 1'b1 : 1'b0;

always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		init_end <= 1'b0;
	end
	else begin
		if(state_cur == INIT_END)begin
			init_end <= 1'b1;
		end
		else begin
			init_end <= 1'b0;
		end
	end
end

always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		cnt_ar <= 4'd0;
	end
	else begin
		if(state_cur == INIT_WAIT)begin
			cnt_ar <= 4'd0;
		end
		else if(state_cur == INIT_AR)begin
			cnt_ar <= cnt_ar + 4'd1;
		end
		else begin
			cnt_ar <= cnt_ar;
		end
	end
end

always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		cnt_wait <= 15'd0;
	end
	else begin
		if(cnt_wait == T_WAIT)begin
			cnt_wait <= cnt_wait;
		end
		else begin
			cnt_wait <= cnt_wait + 1'b1;
		end
	end
end
always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		cnt_fsm <= 4'd0;
	end
	else begin
		if(cnt_fsm_rst)begin
			cnt_fsm <= 4'd0;
		end
		else begin
			cnt_fsm <= cnt_fsm + 4'd1;
		end
	end
end
always@(*)begin
	case(state_cur)
		INIT_WAIT	:	cnt_fsm_rst = 1'b1;
		INIT_TRP    :	cnt_fsm_rst = trp_end_flag ? 1'b1 : 1'b0;
		INIT_TRFC   :	cnt_fsm_rst = trfc_end_flag ? 1'b1 : 1'b0;
		INIT_TMRD   :	cnt_fsm_rst = tmrd_end_flag ? 1'b1 : 1'b0;
		INIT_END    :	cnt_fsm_rst = 1'b1;
		default		:	cnt_fsm_rst = 1'b0;//why?
	endcase
end
//three stage state machine
//the first stage:synchronous timing state transition
always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		state_cur <= INIT_WAIT;
	end
	else begin
		state_cur <= state_next;
	end
end
//the second stage:combinational local
always@(*)begin
	state_next = INIT_WAIT;
	case(state_cur)
		INIT_WAIT	:	begin
			if(wait_end_flag)begin
				state_next = INIT_PRE;
			end
			else begin
				state_next = INIT_WAIT;
			end
		end
		INIT_PRE 	:	begin
			state_next = INIT_TRP;
		end   
		INIT_TRP 	:	begin
			if(trp_end_flag)begin
				state_next = INIT_AR;
			end
			else begin
				state_next = INIT_TRP;
			end
		end   
		INIT_AR  	:	begin
			state_next = INIT_TRFC;
		end   
		INIT_TRFC	:	begin
			if(trfc_end_flag)begin
				if(cnt_ar == AR_MAX)begin
					state_next = INIT_MRS;
				end
				else begin
					state_next = INIT_AR;
				end
			end
			else begin
				state_next = INIT_TRFC;
			end
		end   
		INIT_MRS 	:	begin
			state_next = INIT_TMRD;
		end   
		INIT_TMRD	:	begin
			if(tmrd_end_flag)begin
				state_next = INIT_END;
			end
			else begin
				state_next = INIT_TMRD;
			end
		end   
		INIT_END 	:	begin
			state_next = INIT_END;
		end   
		default		:	begin
			state_next = INIT_WAIT;
		end
	endcase
end
//the third stage:output logic
always@(posedge init_clk or negedge init_rst_n)begin
	if(!init_rst_n)begin
		init_cmd	<= NOP;
		init_bank	<= 2'b11;
		init_addr	<= 13'h1fff;
	end
	else begin
		case(state_cur)
			INIT_WAIT	:begin
				init_cmd	<= NOP;       
				init_bank	<= 2'b11;      	//no care
				init_addr	<= 13'h1fff;   	//no care
			end
			INIT_PRE 	:begin
				init_cmd	<= PRECHARGE;
				init_bank	<= 2'b11;		//all bank
				init_addr	<= 13'h1fff;	//no care
			end
			INIT_TRP 	:begin
				init_cmd	<= NOP;
				init_addr	<= 2'b11;		//no care
				init_bank	<= 13'h1fff;	//no care
			end
			INIT_AR  	:begin
				init_cmd	<= AT_REF;
				init_bank	<= 2'b11;		//no care
				init_addr	<= 13'h1fff;	//no care
			end
			INIT_TRFC	:begin
				init_cmd	<= NOP;
				init_bank	<= 2'b11;		//no care
				init_addr	<= 13'h1fff;	//no care
			end
			INIT_MRS 	:begin
				init_cmd	<= MREG_SET;
				init_bank	<= 2'b00;		//no bank
				init_addr	<=
				{
					3'b000	,			//A12-A10 :reserve
					1'b0	,			//A9=0:burst read & burst write
										//A9=1:burst read & sigle write
					2'b00	,			//{A8,A7}=00,standard mode
					3'b011	,			//{A6,A5,A4}CAS incubation period
					1'b0	,			//A3 burst tramsmission mode 0:oder 1:interlace
					3'b111				//A2 A1 A0 burst length
				};
			end
			INIT_TMRD	:begin
				init_cmd	<= NOP;
				init_bank	<= 2'b11;		//no care
				init_addr	<= 13'h1fff;	//no care
			end
			INIT_END 	:begin
				init_cmd	<= NOP;
				init_bank	<= 2'b11;		//no care
				init_addr	<= 13'h1fff;	//no care
			end
			default 	:begin
				init_cmd	<= NOP;
				init_bank	<= 2'b11;		//no care
				init_addr	<= 13'h1fff;	//no care
			end
		endcase
	end
end
endmodule