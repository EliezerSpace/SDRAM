module sdram(
//------------system
	input			sdram_clk		,
	input			sdram_rst_n		,
	input			clkout			,
//------------FIFO write
	input			wr_fifo_rst		,
	input			wr_fifo_wr_clk	,
	input			wr_fifo_wr_req	,
	input	[15:0]	wr_fifo_wr_data	,
	input	[23:0]	sdram_wr_b_addr ,
	input	[23:0]	sdram_wr_e_addr	,
	input	[9:0]	wr_burst_len	,
	output	[9:0]	wr_fifo_num     ,
//------------FIFO read             
	input			rd_fifo_rst		,
    input			rd_fifo_rd_clk	,
    input			rd_fifo_rd_req	,
    output	[15:0]	rd_fifo_rd_data	,
	input	[23:0]	sdram_rd_b_addr ,
	input	[23:0]	sdram_rd_e_addr	,
	input	[9:0]	rd_burst_len	,
	output	[9:0]	rd_fifo_num     ,
//------------fuction signal                    
	input			read_valid		,
	output			init_end		,
//------------SDRAM interface                   
	output			sdram_cke		,
    output			sdram_cs_n		,
    output			sdram_cas_n		,
    output			sdram_ras_n		,
    output			sdram_we_n		,
    output	[1:0]	sdram_bank		,
    output	[12:0]	sdram_addr		,
    inout	[15:0]	sdram_dq	    ,
	output	[1:0]	sdram_dqm	    ,
	output			sdram_clk_out	
);

assign sdram_clk_out = clkout;
assign sdram_dqm = 2'b00;

wire			sdram_wr_ack	;
wire			sdram_wr_req	;
wire	[15:0]	sdram_wr_data	;
wire	[23:0]	sdram_wr_addr	;

wire			sdram_rd_ack	;
wire			sdram_rd_req	;
wire	[15:0]	sdram_rd_data	;
wire	[23:0]	sdram_rd_addr	;
/*********************************************/
//				fifo_ctrl
/*********************************************/
fifo_ctrl				fifo_ctrl_inst(
	.sdram_clk			(sdram_clk),
	.sdram_rst_n		(sdram_rst_n),
//----------------fifo write
	.wr_fifo_rst		(wr_fifo_rst),	
	.wr_fifo_wr_clk		(wr_fifo_wr_clk),	
	.wr_fifo_wr_req		(wr_fifo_wr_req),	
	.wr_fifo_wr_data	(wr_fifo_wr_data),
	.sdram_wr_b_addr 	(sdram_wr_b_addr),
	.sdram_wr_e_addr	(sdram_wr_e_addr),
	.wr_burst_len		(wr_burst_len),
	.wr_fifo_num     	(wr_fifo_num),
//----------------fifo read
	.rd_fifo_rst		(rd_fifo_rst		),
	.rd_fifo_rd_clk		(rd_fifo_rd_clk		),	
	.rd_fifo_rd_req		(rd_fifo_rd_req		),	
	.rd_fifo_rd_data	(rd_fifo_rd_data	),
	.sdram_rd_b_addr 	(sdram_rd_b_addr 	),
	.sdram_rd_e_addr	(sdram_rd_e_addr	),
	.rd_burst_len		(rd_burst_len		),
	.rd_fifo_num     	(rd_fifo_num     	),

	.read_valid			(read_valid),
	.init_end			(init_end),
//----------------SDRAM write
	.sdram_wr_ack		(sdram_wr_ack),
	.sdram_wr_req		(sdram_wr_req),
	.sdram_wr_addr		(sdram_wr_addr),
	.sdram_wr_data		(sdram_wr_data),
//----------------SDRAM read
	.sdram_rd_ack		(sdram_rd_ack),
	.sdram_rd_data		(sdram_rd_data),
	.sdram_rd_req		(sdram_rd_req),
	.sdram_rd_addr		(sdram_rd_addr)
);
/*********************************************/
//				sdram_ctrl
/*********************************************/
sdram_ctrl			sdram_ctrl_inst(
//-----------system
	.sdram_clk			(sdram_clk),
	.sdram_rst_n		(sdram_rst_n),
	.init_end			(init_end),
//-----------SDRAM write interface
	.sdram_wr_req		(sdram_wr_req),
	.sdram_wr_addr		(sdram_wr_addr),
	.wr_burst_len    	(wr_burst_len),
	.sdram_wr_data   	(sdram_wr_data),
	.sdram_wr_ack    	(sdram_wr_ack),
//-----------SDRAM read interface   
	.sdram_rd_req		(sdram_rd_req),	
    .sdram_rd_addr		(sdram_rd_addr),	
    .rd_burst_len    	(rd_burst_len),
    .sdram_rd_data   	(sdram_rd_data),
    .sdram_rd_ack    	(sdram_rd_ack),
//-----------SDRAM hardware interface
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