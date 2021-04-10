module peerate_cic(
	inout d0,
	inout d1,
	input clk,
	input rst,
	output start,
	output cartridge_region,
	output region_override,
	output rst_host);
	
	// Approx 9s @4Mhz
	parameter REGION_TIMEOUT_TICKS = 36_000_000;
	
	wire clk_prescaled;
		
	wire cic_d411_start;
	wire cic_d413_start;
	wire cic_d411_dead;
	wire cic_d413_dead;
	wire cic_d411_rst_host;
	wire cic_d413_rst_host;
	
	reg [31:0] region_timeout_counter;
	
	always @(posedge clk) begin
		if (rst_host) begin
			region_timeout_counter <= REGION_TIMEOUT_TICKS;
		end else if (region_timeout_counter) begin
			region_timeout_counter <= region_timeout_counter - 1;
		end
	end
	
	prescaler4 prescaler4(
		.clk_in(clk),
		.clk_out(clk_prescaled)
	);
	
	cic #(0) cic_d411(
		.d0(d0),
		.d1(d1),
		.clk(clk_prescaled),
		.rst(rst),
		.seed(1'b0),
		.lock(1'b1),
		.start(cic_d411_start),
		.rst_host(cic_d411_rst_host),
		.dead(cic_d411_dead)
	);
	
	cic #(1) cic_d413(
		.d0(d0),
		.d1(d1),
		.clk(clk_prescaled),
		.rst(rst),
		.seed(1'b0),
		.lock(1'b1),
		.start(cic_d413_start),
		.rst_host(cic_d413_rst_host),
		.dead(cic_d413_dead)
	);
	
	// You can also use cic_d413_start if you want. It doesn't matter, these signals are the same
	assign start = cic_d411_start;
	
	// Cartridge region is 0 if NTSC, 1 if PAL
	assign cartridge_region = cic_d411_dead;
	assign region_override = region_timeout_counter;
	
	assign rst_host = cic_d411_rst_host | cic_d413_rst_host;
endmodule
