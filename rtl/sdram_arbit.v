module sdram_arbit(
	//system
	input				arbit_clk		,
	input				arbit_rst_n		,
	//sdram_init	
	input		[3:0]	init_cmd		,
	input		[12:0]	init_addr		,
	input		[1:0]	init_bank		,
	input				init_end		,
	//sdram auto refresh	
	input				atref_req		,
	input		[3:0]	atref_cmd		,
	input		[1:0]	atref_bank		,
	input		[12:0]	atref_addr		,
	input				atref_end   	,
	//sdram write
	input				wr_req			,
	input				wr_end			,
	input		[3:0]	wr_sdram_cmd	,
	input		[1:0]	wr_sdram_bank	,
	input		[12:0]	wr_sdram_addr	,
	input				wr_sdram_en		,
	input		[15:0]	wr_sdram_data   ,
	//sdram read
	input				rd_end			,
	input				rd_req			,
	input		[3:0]	rd_sdram_cmd	,
	input		[12:0]	rd_sdram_addr	,
	input		[1:0]	rd_sdram_bank	,
	//output ctrl logic
	output	reg			atref_en		,
	output	reg			wr_en			,
	output	reg			rd_en			,
	//sdram interface
	output				sdram_cke		,
	output				sdram_cs_n		,
	output				sdram_cas_n		,
	output				sdram_ras_n		,
	output				sdram_we_n		,
	output	reg	[1:0]	sdram_bank		,
	output	reg	[12:0]	sdram_addr		,
	inout		[15:0]	sdram_dq		
);

parameter	NOP 	= 	4'b0111;
//state code
parameter	INIT	=	3'd0,
			ARBIT	=	3'd1,
			READ	=	3'd2,
			WRITE	=	3'd3,
			ATREF	=	3'd4;

reg [3:0] sdram_cmd;
reg [2:0] state_cur;
reg [2:0] state_next;

assign 	sdram_cke = 1'b1;
assign 	sdram_dq = wr_sdram_en ? wr_sdram_data : 16'hz;
assign	{sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n} = sdram_cmd;


always@(posedge arbit_clk or negedge arbit_rst_n)begin
	if(~arbit_rst_n)
		state_cur <= INIT;
	else
		state_cur <= state_next;
end
always@(*)begin
	case(state_cur)
		INIT    :	state_next = init_end ? ARBIT : INIT;
		ARBIT   :begin
			if(atref_req)
				state_next = ATREF;
			else if(wr_req)
				state_next = WRITE;
			else if(rd_req)
				state_next = READ;
		end
		READ    :	state_next = rd_end ? ARBIT : READ;
		WRITE   :	state_next = wr_end ? ARBIT : WRITE;
		ATREF   :	state_next = atref_end ? ARBIT : ATREF;
		default :	state_next = INIT;
	endcase
end
always@(*)begin
	case(state_cur)
		INIT	:begin
			sdram_cmd 	= 	init_cmd		;
			sdram_bank	=	init_bank		;
			sdram_addr	=	init_addr		;
		end	
	    ARBIT	:begin	
			sdram_cmd 	= 	NOP				;
			sdram_bank	=	2'b11			;
			sdram_addr	=	13'h1fff		;
		end
	    READ	:begin
			sdram_cmd 	= 	rd_sdram_cmd 	;
		    sdram_bank	=	rd_sdram_bank	;
		    sdram_addr	=	rd_sdram_addr	;
		end
	    WRITE	:begin
			sdram_cmd 	= 	wr_sdram_cmd 	;
		    sdram_bank	=	wr_sdram_bank	;
		    sdram_addr	=	wr_sdram_addr	;
		end
	    ATREF	:begin
			sdram_cmd 	= 	atref_cmd 		;
		    sdram_bank	=	atref_bank		;
		    sdram_addr	=	atref_addr		;
		end
		default :begin
			sdram_cmd 	= 	NOP				;
		    sdram_bank	=	2'b11			;
		    sdram_addr	=	13'h1fff		;
		end
	endcase
end
always@(posedge arbit_clk or negedge arbit_rst_n)begin
	if(~arbit_rst_n)begin
		atref_en <= 1'b0;
	end
	else begin
		if(state_cur == ARBIT && atref_req)	
			atref_en <= 1'b1;
		else if(atref_end)
			atref_en <= 1'b0;
	end
end
always@(posedge arbit_clk or negedge arbit_rst_n)begin
	if(~arbit_rst_n)begin
		wr_en <= 1'b0;
	end
	else begin
		if((state_cur == ARBIT) && (~atref_req) && (wr_req))	
			wr_en <= 1'b1;
		else if(wr_end)
			wr_en <= 1'b0;
	end
end
always@(posedge arbit_clk or negedge arbit_rst_n)begin
	if(~arbit_rst_n)begin
		rd_en <= 1'b0;
	end
	else begin
		if((state_cur == ARBIT) && (~atref_req) && (~wr_req) && (rd_req))	
			rd_en <= 1'b1;
		else if(rd_end)
			rd_en <= 1'b0;
	end
end
endmodule