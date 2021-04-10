module uigr_reset_driver(
	input pattern,
	input rst,
	input clk,
	output out,
	output busy);
	
	// 200ms @50MHz
	parameter SHORT_RESET_TICKS = 10_000_000;
	
	// 9s @50MHz
	parameter LONG_RESET_TICKS = 50_000_000 * 9;
	
	reg [31:0] ticks_counter;
	
	initial begin
		ticks_counter <= 0;
	end
	
	always @(posedge clk) begin
		if (rst) begin
			ticks_counter <= pattern ? LONG_RESET_TICKS : SHORT_RESET_TICKS;
		end else if (ticks_counter) begin
			ticks_counter <= ticks_counter - 1;
		end
	end
	
	assign out = !rst && ticks_counter;
	assign busy = rst || ticks_counter;
	
endmodule