//description : sdram auto refresh module
module sdram_atref(
	input					atref_clk	,
	input					atref_rst_n	,
	input					init_end	,	//init end flag
	input					atref_en	,	//auto refresh enable signal
	
	output	reg				atref_req	,	//auto refresh request
	output	reg		[3:0]	atref_cmd	,
	output	reg		[1:0]	atref_bank	,
	output	reg		[12:0]	atref_addr	,
	output	reg				atref_end
);
//cnt max,at times
parameter	T_ATREF = 10'd700;
parameter	AR_MAX 	= 2'd2;	
//waiting time
parameter	TRP	 		= 3'd2,
			TRFC 		= 3'd7;
//command code
parameter	PRECHARGE 	= 4'b0010,
			AT_REF		= 4'b0001,
			NOP 		= 4'b0111,
			MREG_SET 	= 4'b0000;
//state code
parameter	ATREF_IDLE	= 3'b000,
			ATREF_PRE	= 3'b001,//precharge
			ATREF_TRP	= 3'b011,
			ATREF_AR	= 3'b010,//auto refresh
			ATREF_TRFC	= 3'b110,
			ATREF_END	= 3'b111;//auto refresh finish

reg [2:0] state_cur;
reg [2:0] state_next;

wire	trp_end_flag;
wire	trfc_end_flag;

reg		[9:0]	cnt_atref;
reg		[1:0]	cnt_ar;
reg 	[3:0]	cnt_fsm;
reg				cnt_fsm_rst;
wire			atref_ack;

assign atref_ack = (state_cur == ATREF_PRE) ? 1'b1 : 1'b0;

assign trp_end_flag = (state_cur == ATREF_TRP && cnt_fsm == TRP - 1'b1) ? 1'b1 : 1'b0;
assign trfc_end_flag = (state_cur == ATREF_TRFC && cnt_fsm == TRFC - 1'b1) ? 1'b1 : 1'b0;

always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		cnt_atref <= 10'd0;
	end
	else begin
		if(init_end)begin
			if(cnt_atref == T_ATREF)
				cnt_atref <= 10'd0;
			else
				cnt_atref <= cnt_atref + 1'b1;
		end
		else begin
			cnt_atref <= cnt_atref;
		end
	end
end
always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		atref_req <= 1'b0;
	end
	else begin
		if(cnt_atref == T_ATREF - 1'b1)
			atref_req <= 1'b1;
		else if(atref_ack)
			atref_req <= 1'b0;
		else
			atref_req <= atref_req;
	end
end
always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		cnt_ar <= 2'd0;
	end
	else begin
		if(state_cur == ATREF_IDLE)
			cnt_ar <= 2'd0;
		else if(state_cur == ATREF_AR)
			cnt_ar <= cnt_ar + 1'b1;
		else
			cnt_ar <= cnt_ar;
	end
end

always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		atref_end <= 1'b0;
	end
	else begin
		if(trfc_end_flag && cnt_ar == 2'd2)
			atref_end <= 1'b1;
		else
			atref_end <= 1'b0;
	end
end
always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		cnt_fsm <= 4'd0;
	end
	else begin
		if(cnt_fsm_rst)
			cnt_fsm <= 4'd0;
		else
			cnt_fsm <= cnt_fsm + 1'b1;
	end
end
always@(*)begin
	case(state_cur)
		ATREF_IDLE	:	cnt_fsm_rst = 1'b1;
		ATREF_TRP	:	cnt_fsm_rst = trp_end_flag ? 1'b1 : 1'b0;
		ATREF_TRFC	:	cnt_fsm_rst = trfc_end_flag ? 1'b1 : 1'b0;
		ATREF_END	:	cnt_fsm_rst = 1'b1;
		default		:	cnt_fsm_rst = 1'b1;
	endcase
end
//state machine three stages
//the first stage
always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		state_cur <= ATREF_IDLE;
	end
	else begin
		state_cur <= state_next;
	end
end
//the second stage
always@(*)begin
	state_next = ATREF_IDLE;
	case(state_cur)
		ATREF_IDLE	:begin
			if(init_end & atref_en)
				state_next = ATREF_PRE;
			else
				state_next = ATREF_IDLE;
		end
		ATREF_PRE	:begin
			state_next = ATREF_TRP;
		end
		ATREF_TRP	:begin
			if(trp_end_flag)
				state_next = ATREF_AR;
			else
				state_next = ATREF_TRP;
		end
		ATREF_AR	:begin
			state_next = ATREF_TRFC;
		end
		ATREF_TRFC	:begin
			if(trfc_end_flag)begin
				if(cnt_ar == AR_MAX)
					state_next = ATREF_END;
				else
					state_next = ATREF_AR;
			end
			else begin
				state_next = ATREF_TRFC;
			end
				
		end
		ATREF_END	:begin
			state_next = ATREF_IDLE;
		end
		default		:begin
			state_next = ATREF_IDLE;
		end
	endcase
end
//the third stage
always@(posedge atref_clk or negedge atref_rst_n)begin
	if(!atref_rst_n)begin
		atref_cmd	<= NOP;
		atref_bank	<= 2'b11;
		atref_addr	<= 13'h1fff;
	end
	else begin
		case(state_cur)
			ATREF_IDLE	:begin
				atref_cmd	<= NOP;
			    atref_bank	<= 2'b11;
			    atref_addr	<= 13'h1fff;
			end
			ATREF_PRE	:begin
				atref_cmd	<= PRECHARGE;
			    atref_bank	<= 2'b11;
			    atref_addr	<= 13'h1fff;
			end
		    ATREF_TRP	:begin
				atref_cmd	<= NOP;
			    atref_bank	<= 2'b11;
			    atref_addr	<= 13'h1fff;
			end
		    ATREF_AR	:begin
				atref_cmd	<= AT_REF;
				atref_bank	<= 2'b11;
				atref_addr	<= 13'h1fff;
			end
		    ATREF_TRFC	:begin
				atref_cmd	<= NOP;
			    atref_bank	<= 2'b11;
				atref_addr	<= 13'h1fff;
			end
		    ATREF_END	:begin
				atref_cmd	<= NOP;
				atref_bank	<= 2'b11;
				atref_addr	<= 13'h1fff;
			end
			default		:begin
				atref_cmd	<= NOP;
			    atref_bank	<= 2'b11;
			    atref_addr	<= 13'h1fff;
			end
		endcase
	end
end
endmodule