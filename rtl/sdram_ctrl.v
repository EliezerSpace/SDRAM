module sdram_ctrl(
//-----------system
	input			sdram_clk		,
	input			sdram_rst_n		,
	output			init_end		,
//-----------SDRAM write interface
	input			sdram_wr_req	,
	input	[23:0]	sdram_wr_addr	,
	input	[9:0]	wr_burst_len    ,
	input	[15:0]	sdram_wr_data   ,
	output			sdram_wr_ack    ,
//-----------SDRAM read interface   
	input			sdram_rd_req	,	
    input	[23:0]	sdram_rd_addr	,	
    input	[9:0]	rd_burst_len    ,
    output	[15:0]	sdram_rd_data   ,
    output			sdram_rd_ack    ,
//-----------SDRAM hardware interface
	output			sdram_cke		,
    output			sdram_cs_n		,
    output			sdram_cas_n		,
    output			sdram_ras_n		,
    output			sdram_we_n		,
    output	[1:0]	sdram_bank		,
    output	[12:0]	sdram_addr		,
    inout	[15:0]	sdram_dq		
);

wire	[3:0]	init_cmd 		;
wire	[1:0]	init_bank		;
wire	[12:0]	init_addr		;	
	
wire	[3:0]	atref_cmd		;
wire	[1:0]	atref_bank		;
wire	[12:0]	atref_addr		;
wire			atref_en		;	
wire			atref_req		;
wire			atref_end		;

wire	[3:0]	wr_sdram_cmd	;
wire	[1:0]	wr_sdram_bank	;
wire	[12:0]	wr_sdram_addr	;
wire			wr_en			;	
wire			wr_end			;
wire			wr_sdram_en		;
wire	[15:0]	wr_sdram_data	;

wire	[3:0]	rd_sdram_cmd	;
wire	[1:0]	rd_sdram_bank	;
wire	[12:0]	rd_sdram_addr	;
wire			rd_en			;	
wire			rd_end			;



//*****************SDRAM init*****************
sdram_init			sdram_init_inst(
	.init_clk			(sdram_clk),//init clock
	.init_rst_n			(sdram_rst_n),//init reset negedge valid
	
	.init_cmd			(init_cmd),//command
	.init_addr			(init_addr),//address
	.init_bank			(init_bank),//bank
	.init_end			(init_end) //init end valid signal
);
//*****************SDRAM auto refresh*****************
sdram_atref			sdram_atref_inst(
	.atref_clk			(sdram_clk),
	.atref_rst_n		(sdram_rst_n),
	.init_end			(init_end),	//init end flag
	.atref_en			(atref_en),	//auto refresh enable signal
	
	.atref_req			(atref_req),	//auto refresh request
	.atref_cmd			(atref_cmd	),
	.atref_bank			(atref_bank),
	.atref_addr			(atref_addr),
	.atref_end      	(atref_end)
);
//*****************SDRAM write*****************
sdram_wr			sdram_wr_inst(
	.wr_clk				(sdram_clk),
	.wr_rst_n			(sdram_rst_n),
	.init_end			(init_end),
	.wr_en				(wr_en),
	.wr_addr			(sdram_wr_addr),
	.wr_data			(sdram_wr_data),
	.wr_burst_len		(wr_burst_len),

	.wr_ack				(sdram_wr_ack),
	.wr_end				(wr_end),
	.wr_sdram_cmd		(wr_sdram_cmd	),
	.wr_sdram_bank		(wr_sdram_bank	),
	.wr_sdram_addr		(wr_sdram_addr	),
	.wr_sdram_en		(wr_sdram_en),
	.wr_sdram_data      (wr_sdram_data)
);
//*****************SDRAM read*****************
sdram_read			sdram_read_inst(
	.rd_clk				(sdram_clk),	
	.rd_rst_n			(sdram_rst_n),
	.rd_en				(rd_en),
	.init_end			(init_end),
	.rd_addr			(sdram_rd_addr),
	.rd_data			(sdram_dq),
	.rd_burst_len		(rd_burst_len),

	.rd_end				(rd_end),
	.rd_ack				(sdram_rd_ack),
	.rd_sdram_cmd		(rd_sdram_cmd),
	.rd_sdram_addr		(rd_sdram_addr),
	.rd_sdram_bank		(rd_sdram_bank),
	.rd_sdram_data	    (sdram_rd_data)
);
//*****************SDRAM arbit*****************
sdram_arbit			sdram_arbit_inst(
	//system
	.arbit_clk			(sdram_clk),
	.arbit_rst_n		(sdram_rst_n),
	//sdram_init	
	.init_cmd			(init_cmd),
	.init_addr			(init_addr),
	.init_bank			(init_bank),
	.init_end			(init_end),
	//sdram auto refresh	
	.atref_req			(atref_req),
	.atref_cmd			(atref_cmd	),
	.atref_bank			(atref_bank	),
	.atref_addr			(atref_addr	),
	.atref_end   		(atref_end),
	//sdram write
	.wr_req				(sdram_wr_req),
	.wr_end				(wr_end),
	.wr_sdram_cmd		(wr_sdram_cmd),
	.wr_sdram_bank		(wr_sdram_bank),
	.wr_sdram_addr		(wr_sdram_addr),
	.wr_sdram_en		(wr_sdram_en),
	.wr_sdram_data   	(wr_sdram_data),
	//sdram read
	.rd_end				(rd_end),
	.rd_req				(sdram_rd_req),
	.rd_sdram_cmd		(rd_sdram_cmd),
	.rd_sdram_addr		(rd_sdram_addr),
	.rd_sdram_bank		(rd_sdram_bank),
	//output ctrl logic
	.atref_en			(atref_en),
	.wr_en				(wr_en),
	.rd_en				(rd_en),
	//sdram interface
	.sdram_cke			(sdram_cke	),
	.sdram_cs_n			(sdram_cs_n	),
	.sdram_cas_n		(sdram_cas_n),
	.sdram_ras_n		(sdram_ras_n),
	.sdram_we_n			(sdram_we_n	),
	.sdram_bank			(sdram_bank	),
	.sdram_addr			(sdram_addr	),
	.sdram_dq		    (sdram_dq	)
);
endmodule