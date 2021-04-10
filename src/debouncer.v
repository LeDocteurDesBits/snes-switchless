module debouncer(
	input in,
	input clk,
	output reg out);
	
	// 10ms @50MHz
	parameter TICKS = 500_000;
	
	parameter INVERT_OUTPUT = 1'b0;
	
	reg [31:0] counter; // TODO: Reduce the bits count used for this counter
	
	initial begin
		counter <= 32'b0;
	end
	
	always @(posedge clk) begin
		counter <= counter + 1;
		
		if (counter == TICKS) begin
			counter <= 32'b0;
			out <= INVERT_OUTPUT ^ in;
		end
	end
endmodule