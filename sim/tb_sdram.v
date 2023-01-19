`timescale 1ns/1ns
module tb_sdram;

//-----------------system
reg		sys_clk;
reg 	sys_rst_n;
wire	rst_n;
//-----------------PLL
wire	clk_50m			;
wire	clk_100m		;
wire	clk_100m_shift	;
wire	locked			;
//-----------------SDRAM
wire			sdram_cke		;	
wire			sdram_cs_n		;	
wire			sdram_cas_n		;
wire			sdram_ras_n		;
wire			sdram_we_n		;	
wire	[1:0]	sdram_bank		;	
wire	[12:0]	sdram_addr		;	
wire	[15:0]	sdram_dq	    ;	
wire	[1:0]	sdram_dqm	    ;	
wire			sdram_clk_out	;    

wire	init_end		;
wire	[9:0]	wr_fifo_num;
wire	[9:0]	rd_fifo_num;

reg		read_valid;

reg		wr_en;
wire	[15:0]	rd_fifo_rd_data;
reg				rd_fifo_rd_req;

reg				wr_fifo_wr_req;
reg		[15:0]	wr_fifo_wr_data;
reg		[3:0]	cnt_rd_data;
reg		[2:0]	cnt_wr_wait;

defparam sdram_model_plus_inst.addr_bits = 13;
defparam sdram_model_plus_inst.data_bits = 16;
defparam sdram_model_plus_inst.col_bits = 9;
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024;

assign rst_n = sys_rst_n & locked;

initial begin
	sys_clk = 0;
	sys_rst_n = 0;
	#100
	sys_rst_n = 1;
end
always#10 sys_clk = ~sys_clk;

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)
		read_valid <= 1'b1;
	else if(rd_fifo_num == 10'd30)
		read_valid <= 1'b0;
end

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		wr_en <= 1'b1;
	end
	else begin
		if(wr_fifo_num == 10'd30)
			wr_en <= 1'b0;
		else
			wr_en <= wr_en;
	end
end

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		cnt_wr_wait <= 3'd0;
	end
	else begin
		if(wr_en)
			cnt_wr_wait <= cnt_wr_wait + 1'b1;
		else
			cnt_wr_wait <= 3'd0;
	end
end

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		wr_fifo_wr_req <= 1'b0;
	end
	else begin
		if(cnt_wr_wait == 3'd7)
			wr_fifo_wr_req <= 1'b1;
		else
			wr_fifo_wr_req <= 1'b0;
	end
end

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		wr_fifo_wr_data <= 16'b0;
	end
	else begin
		if(cnt_wr_wait == 3'd7)
			wr_fifo_wr_data <= wr_fifo_wr_data + 1'b1;
		else
			wr_fifo_wr_data <= wr_fifo_wr_data;
	end
end

//rd_fifo_rd_req
always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		rd_fifo_rd_req <= 1'b0;
	end
	else begin
		if(cnt_rd_data == 4'd9)
			rd_fifo_rd_req <= 1'b0;
		else if(~wr_en)
			rd_fifo_rd_req <= 1'b1;
	end
end

always@(posedge clk_50m or negedge rst_n)begin
	if(~rst_n)begin
		cnt_rd_data <= 4'b0;
	end
	else begin
		if(rd_fifo_rd_req)
			cnt_rd_data <= cnt_rd_data + 1'b1;
		else 
			cnt_rd_data <= 4'b0;
	end
end

//*******************************************
//*****************PLL***********************
pll 				pll_inst(
	.areset				(~sys_rst_n),		
	.inclk0				(sys_clk),
	.c0					(clk_50m),
	.c1					(clk_100m),
	.c2					(clk_100m_shift),
	.locked				(locked)
);
//*********************************************
//*****************SDRAM***********************
sdram				sdram_inst(
//------------system
	.sdram_clk			(clk_100m),
	.sdram_rst_n		(rst_n),
	.clkout				(clk_100m_shift),
//------------FIFO write
	.wr_fifo_rst		(~rst_n),
	.wr_fifo_wr_clk		(clk_50m),
	.wr_fifo_wr_req		(wr_fifo_wr_req),
	.wr_fifo_wr_data	(wr_fifo_wr_data),
	.sdram_wr_b_addr 	(24'd0	),
	.sdram_wr_e_addr	(24'd30	),
	.wr_burst_len		(10'd10	),
	.wr_fifo_num     	(wr_fifo_num),
//------------FIFO read            
	.rd_fifo_rst		(~rst_n),
    .rd_fifo_rd_clk		(clk_50m),
    .rd_fifo_rd_req		(rd_fifo_rd_req),
    .rd_fifo_rd_data	(rd_fifo_rd_data),
	.sdram_rd_b_addr 	(24'd0	),
	.sdram_rd_e_addr	(24'd30	),
	.rd_burst_len		(10'd10	),
	.rd_fifo_num     	(rd_fifo_num),
//fuction signal                 
	.read_valid			(read_valid),
	.init_end			(init_end),
//SDRAM interface                  
	.sdram_cke			(sdram_cke		),
    .sdram_cs_n			(sdram_cs_n		),
    .sdram_cas_n		(sdram_cas_n	),
    .sdram_ras_n		(sdram_ras_n	),
    .sdram_we_n			(sdram_we_n		),
    .sdram_bank			(sdram_bank		),
    .sdram_addr			(sdram_addr		),
    .sdram_dq	    	(sdram_dq	    ),
	.sdram_dqm	    	(sdram_dqm	    ),
	.sdram_clk_out	    (sdram_clk_out	)
);
//*********************************************
//*****************SDRAM model*****************
sdram_model_plus 	sdram_model_plus_inst(
	.Dq					(sdram_dq), 
	.Addr				(sdram_addr), 	
	.Ba					(sdram_bank), 
	.Clk				(sdram_clk_out), 
	.Cke				(sdram_cke), 
	.Cs_n				(sdram_cs_n), 
	.Ras_n				(sdram_ras_n), 
	.Cas_n				(sdram_cas_n), 
	.We_n				(sdram_we_n), 
	.Dqm				(2'b0),
	.Debug   			(1'b1)
);
endmodule