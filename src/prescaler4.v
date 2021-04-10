module prescaler4(
	input clk_in,
	output clk_out);

	reg [1:0] counter;
	
	initial begin
		counter <= 2'b00;
	end
	
	always @(posedge clk_in) begin
		counter <= counter + 2'b01;
	end
	
	assign clk_out = counter[1];
endmodule
