module top(
	input gamepad_data,
	input gamepad_clk,
	input gamepad_latch,
	input reset_button,
	
	inout cic_d0,
	inout cic_d1,
	input cic_clk,
	output cic_start,
	output cic_rst_host,
	
	input [7:0] d4_patch_pa,
	input d4_patch_pardn,
	output d4_patch_out,
	
	input clk,
	output [1:0] led,
	output effective_region);

	wire uigr_d4_en;
	wire [1:0] uigr_region;
	wire uigr_cic_reset;
		
	wire cic_cartridge_region;
	wire cic_region_override;
	
	uigr uigr(
		.gamepad_data(gamepad_data),
		.gamepad_clk(gamepad_clk),
		.gamepad_latch(gamepad_latch),
		.reset_button(reset_button),
		.clk(clk),
		.d4_en(uigr_d4_en),
		.region(uigr_region),
		.region_timeout_en(uigr_region_timeout_en),
		.led(led),
		.cic_reset(uigr_cic_reset)
	);
	
	peerate_cic peerate_cic(
		.d0(cic_d0),
		.d1(cic_d1),
		.clk(cic_clk),
		.rst(~reset_button /*uigr_cic_reset*/),
		.start(cic_start),
		.cartridge_region(cic_cartridge_region),
		.region_override(cic_region_override),
		.rst_host(cic_rst_host)
	);
	
	d4_patch d4_patch(
		.in(effective_region),
		.pa(d4_patch_pa),
		.pardn(d4_patch_pardn),
		.en(uigr_d4_en),
		.out(d4_patch_out)
	);
	
	assign effective_region = ((uigr_region_timeout_en && cic_region_override) || uigr_region[1]) ? cic_cartridge_region : uigr_region[0];
endmodule