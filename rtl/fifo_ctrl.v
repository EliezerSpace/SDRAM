module fifo_ctrl(
	input			sdram_clk		,
	input			sdram_rst_n		,
//----------------fifo write
	input			wr_fifo_rst		,	
	input			wr_fifo_wr_clk	,	
	input			wr_fifo_wr_req	,	
	input	[15:0]	wr_fifo_wr_data	,
	input	[23:0]	sdram_wr_b_addr ,
	input	[23:0]	sdram_wr_e_addr	,
	input	[9:0]	wr_burst_len	,
	output	[9:0]	wr_fifo_num     ,
//----------------fifo read
	input			rd_fifo_rst		,
	input			rd_fifo_rd_clk	,	
	input			rd_fifo_rd_req	,	
	output	[15:0]	rd_fifo_rd_data	,
	input	[23:0]	sdram_rd_b_addr ,
	input	[23:0]	sdram_rd_e_addr	,
	input	[9:0]	rd_burst_len	,
	output	[9:0]	rd_fifo_num     ,

	input			read_valid		,
	input			init_end		,
//----------------SDRAM write
	input			sdram_wr_ack	,
	output	reg		sdram_wr_req	,
	output	reg[23:0]	sdram_wr_addr	,
	output	[15:0]	sdram_wr_data	,
//----------------SDRAM read
	input			sdram_rd_ack	,
	input	[15:0]	sdram_rd_data	,
	output	reg		sdram_rd_req	,
	output	reg[23:0]	sdram_rd_addr	
);

wire	sdram_wr_ack_fall;
wire	sdram_rd_ack_fall;

reg		sdram_wr_ack_d1;
reg		sdram_wr_ack_d2;
reg		sdram_rd_ack_d1;
reg		sdram_rd_ack_d2;

always@(posedge sdram_clk or negedge sdram_rst_n)begin
	if(~sdram_rst_n)begin
		sdram_wr_ack_d1	<= 1'b0;
		sdram_wr_ack_d2	<= 1'b0;
	end
	else begin
		sdram_wr_ack_d1 <= sdram_wr_ack;
		sdram_wr_ack_d2 <= sdram_wr_ack_d1;
	end
end

always@(posedge sdram_clk or negedge sdram_rst_n)begin
	if(~sdram_rst_n)begin
		sdram_rd_ack_d1	<= 1'b0;
		sdram_rd_ack_d2	<= 1'b0;
	end
	else begin
		sdram_rd_ack_d1 <= sdram_rd_ack;
		sdram_rd_ack_d2 <= sdram_rd_ack_d1;
	end
end

assign sdram_wr_ack_fall = (sdram_wr_ack_d2 & ~sdram_wr_ack_d1);
assign sdram_rd_ack_fall = (sdram_rd_ack_d2 & ~sdram_rd_ack_d1);

always@(posedge sdram_clk or negedge sdram_rst_n)begin
	if(~sdram_rst_n)begin
		sdram_wr_addr <= 24'd0;
	end
	else begin
		if(wr_fifo_rst)begin
			sdram_wr_addr <= sdram_wr_b_addr;
		end
		else if(sdram_wr_ack_fall)begin
			if(sdram_wr_addr < (sdram_wr_e_addr - wr_burst_len))
				sdram_wr_addr <= sdram_wr_addr + wr_burst_len;
			else
				sdram_wr_addr <= sdram_wr_b_addr;
		end
	end
end
always@(posedge sdram_clk or negedge sdram_rst_n)begin
	if(~sdram_rst_n)begin
		sdram_rd_addr <= 24'd0;
	end
	else begin
		if(rd_fifo_rst)begin
			sdram_rd_addr <= sdram_rd_b_addr;
		end
		else if(sdram_rd_ack_fall)begin
			if(sdram_rd_addr < (sdram_rd_e_addr - rd_burst_len))
				sdram_rd_addr <= sdram_rd_addr + rd_burst_len;
			else
				sdram_rd_addr <= sdram_rd_b_addr;
		end
	end
end

always@(posedge sdram_clk or negedge sdram_rst_n)begin
	if(~sdram_rst_n)begin
		sdram_wr_req	<=	1'b0;
		sdram_rd_req	<=	1'b0;
	end
	else begin
		if(init_end)begin
			if(wr_fifo_num >= wr_burst_len)begin
				sdram_wr_req	<=	1'b1;
			    sdram_rd_req	<=	1'b0;
			end
			else if((rd_fifo_num < rd_burst_len) && (read_valid))begin
				sdram_wr_req	<=	1'b0;
				sdram_rd_req	<=	1'b1;
			end	
		end
		else begin
			sdram_wr_req	<=	1'b0;
			sdram_rd_req	<=	1'b0;
		end
	end
end
//fifo write
fifo_wr 		fifo_wr_inst(
	.aclr		(wr_fifo_rst || ~sdram_rst_n),
	.data		(wr_fifo_wr_data),
	.rdclk		(sdram_clk),
	.rdreq		(sdram_wr_ack),
	.wrclk		(wr_fifo_wr_clk),
	.wrreq		(wr_fifo_wr_req),
	.q			(sdram_wr_data),
	.rdusedw	(wr_fifo_num),
	.wrusedw     ()
);
//fifo read
fifo_rd 		fifo_rd_inst(
	.aclr		(rd_fifo_rst || ~sdram_rst_n),
	.data		(sdram_rd_data),
	.rdclk		(rd_fifo_rd_clk),
	.rdreq		(rd_fifo_rd_req),
	.wrclk		(sdram_clk),
	.wrreq		(sdram_rd_ack),
	.q			(rd_fifo_rd_data),
	.rdusedw		(),
	.wrusedw     (rd_fifo_num)	
);
endmodule