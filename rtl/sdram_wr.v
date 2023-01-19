module sdram_wr(
	input			wr_clk			,
	input			wr_rst_n		,
	input			init_end		,
	input			wr_en			,
	input	[23:0]	wr_addr			,
	input	[15:0]	wr_data			,
	input	[9:0]	wr_burst_len	,
	
	output			wr_ack			,
	output			wr_end			,
	output	reg[3:0]	wr_sdram_cmd	,
	output	reg[1:0]	wr_sdram_bank	,
	output	reg[12:0]	wr_sdram_addr	,
	output	reg		wr_sdram_en		,
	output	[15:0]	wr_sdram_data
);

//waiting time parameter
parameter	TRP = 3'd2,
			TRCD = 3'd2;
//command parameter
parameter	NOP 		= 4'b0111,
			PRECHARGE   = 4'b0010,
			ACTIVE      = 4'b0011,
			WRITE       = 4'b0100,
			BURST_STOP  = 4'b0110;
//state code
parameter	WR_IDLE 	= 3'b000,
			WR_ACT		= 3'b001,
			WR_TRCD		= 3'b011,
			WR_WR_CMD 	= 3'b010,
			WR_DATA		= 3'b100,
			WR_PRE		= 3'b101,
			WR_TRP		= 3'b111,
			WR_END		= 3'b110;
//state define
reg [2:0] state_cur;
reg [2:0] state_next;
//flag
wire	trp_end_flag;
wire	trcd_end_flag;
wire	wr_end_flag;

reg			cnt_fsm_rst;
reg [9:0] 	cnt_fsm;

assign wr_end = (state_cur == WR_END) ? 1'b1 : 1'b0;
assign wr_ack = (state_cur == WR_WR_CMD) || ((state_cur == WR_DATA) && (cnt_fsm <= wr_burst_len - 2'd2));
assign wr_sdram_data = wr_sdram_en ? wr_data : 16'd0;


assign trp_end_flag = (state_cur == WR_TRP && cnt_fsm == TRP - 1'b1) ? 1'b1 : 1'b0;
assign trcd_end_flag = (state_cur == WR_TRCD && cnt_fsm == TRCD - 1'b1) ? 1'b1 : 1'b0;
assign wr_end_flag = (state_cur == WR_DATA && cnt_fsm == wr_burst_len - 1'b1) ? 1'b1 : 1'b0;


always@(posedge wr_clk or negedge wr_rst_n)begin
	if(~wr_rst_n)begin
		wr_sdram_en <= 1'b0;
	end
	else begin
		wr_sdram_en <= wr_ack;
	end
end

always@(*)begin
	case(state_cur)
		WR_IDLE 	: cnt_fsm_rst = 1'b1;
		WR_TRCD 	: cnt_fsm_rst = trcd_end_flag ? 1'b1 : 1'b0;
		WR_WR_CMD 	: cnt_fsm_rst = 1'b1;
		WR_DATA		: cnt_fsm_rst = wr_end_flag ? 1'b1 : 1'b0;
		WR_PRE		: cnt_fsm_rst = 1'b1;
		WR_TRP		: cnt_fsm_rst = trp_end_flag ? 1'b1 : 1'b0;
		WR_END		: cnt_fsm_rst = 1'b1;
		default		: cnt_fsm_rst = 1'b1;
	endcase
end
always@(posedge wr_clk or negedge wr_rst_n)begin
	if(~wr_rst_n)begin
		cnt_fsm <= 10'd0;
	end
	else begin
		if(cnt_fsm_rst)
			cnt_fsm <= 10'd0;
		else
			cnt_fsm <= cnt_fsm + 1'b1;
	end
end

always@(posedge wr_clk or negedge wr_rst_n)begin
	if(~wr_rst_n)
		state_cur <= WR_IDLE;
	else
		state_cur <= state_next;
end
always@(*)begin
	case(state_cur)
		WR_IDLE 	:begin
			if(init_end & wr_en)
				state_next = WR_ACT;
			else
				state_next = WR_IDLE;
		end
	    WR_ACT		:begin
			state_next = WR_TRCD;
		end
	    WR_TRCD		:begin
			if(trcd_end_flag)
				state_next = WR_WR_CMD;
			else
				state_next = WR_TRCD;
		end
	    WR_WR_CMD 	:begin
			state_next = WR_DATA;
		end
	    WR_DATA		:begin
			if(wr_end_flag)
				state_next = WR_PRE;
			else
				state_next = WR_DATA;
		end
	    WR_PRE		:begin
			state_next = WR_TRP;
		end
	    WR_TRP		:begin
			if(trp_end_flag)
				state_next = WR_END;
			else
				state_next = WR_TRP;
		end
	    WR_END		:begin
			state_next = WR_IDLE;
		end
		default		:begin
			state_next = WR_IDLE;
		end
	endcase
end
always@(posedge wr_clk or negedge wr_rst_n)begin
	if(~wr_rst_n)begin
		wr_sdram_cmd	<=	NOP;
		wr_sdram_bank	<=	2'b11;
		wr_sdram_addr	<=	13'h1fff;
	end
	else begin
		case(state_cur)
			WR_IDLE 	:begin
				wr_sdram_cmd	<=	NOP;
				wr_sdram_bank	<=	2'b11;
				wr_sdram_addr	<=	13'h1fff;
			end
		    WR_ACT		:begin
				wr_sdram_cmd	<=	ACTIVE;
			    wr_sdram_bank	<=	wr_addr[23:22];
			    wr_sdram_addr	<=	wr_addr[21:9];
			end
		    WR_TRCD		:begin
				wr_sdram_cmd	<=	NOP;
			    wr_sdram_bank	<=	2'b11;
			    wr_sdram_addr	<=	13'h1fff;
			end
		    WR_WR_CMD 	:begin
				wr_sdram_cmd	<=	WRITE;
			    wr_sdram_bank	<=	wr_addr[23:22];
			    wr_sdram_addr	<=	{4'b0000,wr_addr[8:0]};
			end
		    WR_DATA		:begin
				wr_sdram_bank	<=	2'b11;
			    wr_sdram_addr	<=	13'h1fff;
			    if(wr_end_flag)
					wr_sdram_cmd	<=	BURST_STOP;
				else
					wr_sdram_cmd	<=	NOP;
			end
		    WR_PRE		:begin
				wr_sdram_cmd	<=	PRECHARGE;
			    wr_sdram_bank	<=	wr_addr[23:22];
			    wr_sdram_addr	<=	13'h0400;//A10 = "1"
			end
		    WR_TRP		:begin
				wr_sdram_cmd	<=	NOP;
			    wr_sdram_bank	<=	2'b11;
			    wr_sdram_addr	<=	13'h1fff;
			end
		    WR_END		:begin
				wr_sdram_cmd	<=	NOP;
				wr_sdram_bank	<=	2'b11;
				wr_sdram_addr	<=	13'h1fff;
			end
			default		:begin
				wr_sdram_cmd	<=	NOP;
			    wr_sdram_bank	<=	2'b11;
			    wr_sdram_addr	<=	13'h1fff;
			end
		endcase
	end
end
endmodule