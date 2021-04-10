module uigr_led_driver(
	input [3:0] pattern,
	input rst,
	input clk,
	output reg [1:0] led,
	output reg busy);
	
	parameter COMMON_CATHODE = 		1'b1;
	parameter SHORT_INTERVAL_TICKS = 5_000_000;
	parameter LONG_INTERVAL_TICKS = 	12_500_000;
	
	localparam LED_ON = 	(COMMON_CATHODE) ? 1'b1 : 1'b0;
	localparam LED_OFF = (COMMON_CATHODE) ? 1'b0 : 1'b1;
	
	localparam OP_LED_OFF = 		4'b0000;
	localparam OP_LED_GREEN = 		4'b0001;
	localparam OP_LED_RED = 		4'b0010;
	localparam OP_LED_YELLOW = 	4'b0011;
	localparam OP_WAIT_SHORT = 	4'b0100;
	localparam OP_WAIT_LONG = 		4'b0101;
	localparam OP_STATE_SAVE = 	4'b1000;
	localparam OP_STATE_RESTORE = 4'b1001;
	localparam OP_HALT = 			4'b1111;
	
	// I should not use a capitalized name but that's a constant.
	// I can't use localparam here...
	reg [3:0] PATTERNS [0:255];
	
	reg [7:0] pc; // Process counter
	reg [31:0] tc; // Ticks counter
	reg [1:0] led_save_state;
	
	initial begin
		busy <= 0;
		pc <= 8'b0;
		tc <= 32'b0;
		
		// Default: Yellow LED (cartridge region)
		led <= {LED_ON, LED_ON};
		led_save_state <= {LED_ON, LED_ON};
		
		// 0000 => Solid off
		PATTERNS[0] <= OP_LED_OFF;
		PATTERNS[1] <= OP_HALT;
		
		// 0001 => Solid green
		PATTERNS[16] <= OP_LED_GREEN;
		PATTERNS[17] <= OP_HALT;
		
		// 0010 => Solid red
		PATTERNS[32] <= OP_LED_RED;
		PATTERNS[33] <= OP_HALT;
		
		// 0011 => Solid yellow
		PATTERNS[48] <= OP_LED_YELLOW;
		PATTERNS[49] <= OP_HALT;
		
		// 0100 => Off -> long wait -> red -> long wait -> yellow -> long wait -> green -> long wait -> off -> long wait -> restore state
		PATTERNS[64] <= OP_LED_OFF;
		PATTERNS[65] <= OP_WAIT_LONG;
		PATTERNS[66] <= OP_LED_RED;
		PATTERNS[67] <= OP_WAIT_LONG;
		PATTERNS[68] <= OP_LED_YELLOW;
		PATTERNS[69] <= OP_WAIT_LONG;
		PATTERNS[70] <= OP_LED_GREEN;
		PATTERNS[71] <= OP_WAIT_LONG;
		PATTERNS[72] <= OP_LED_OFF;
		PATTERNS[73] <= OP_WAIT_LONG;
		PATTERNS[74] <= OP_STATE_RESTORE;
		PATTERNS[75] <= OP_HALT;
		
		// 0101 => Off -> long wait -> green -> long wait -> yellow -> long wait -> red -> long wait -> off -> long wait -> restore state
		PATTERNS[80] <= OP_LED_OFF;
		PATTERNS[81] <= OP_WAIT_LONG;
		PATTERNS[82] <= OP_LED_GREEN;
		PATTERNS[83] <= OP_WAIT_LONG;
		PATTERNS[84] <= OP_LED_YELLOW;
		PATTERNS[85] <= OP_WAIT_LONG;
		PATTERNS[86] <= OP_LED_RED;
		PATTERNS[87] <= OP_WAIT_LONG;
		PATTERNS[88] <= OP_LED_OFF;
		PATTERNS[89] <= OP_WAIT_LONG;
		PATTERNS[90] <= OP_STATE_RESTORE;
		PATTERNS[91] <= OP_HALT;
		
		// 0110 => Off -> long wait -> green -> long wait -> off -> long wait -> green -> long wait -> off -> long wait -> restore state
		PATTERNS[96] <= OP_LED_OFF;
		PATTERNS[97] <= OP_WAIT_LONG;
		PATTERNS[98] <= OP_LED_GREEN;
		PATTERNS[99] <= OP_WAIT_LONG;
		PATTERNS[100] <= OP_LED_OFF;
		PATTERNS[101] <= OP_WAIT_LONG;
		PATTERNS[102] <= OP_LED_GREEN;
		PATTERNS[103] <= OP_WAIT_LONG;
		PATTERNS[104] <= OP_LED_OFF;
		PATTERNS[105] <= OP_WAIT_LONG;
		PATTERNS[106] <= OP_STATE_RESTORE;
		PATTERNS[107] <= OP_HALT;
		
		// 0111 => Off -> long wait -> red -> long wait -> off -> long wait -> red -> long wait -> off -> long wait -> restore state
		PATTERNS[112] <= OP_LED_OFF;
		PATTERNS[113] <= OP_WAIT_LONG;
		PATTERNS[114] <= OP_LED_RED;
		PATTERNS[115] <= OP_WAIT_LONG;
		PATTERNS[116] <= OP_LED_OFF;
		PATTERNS[117] <= OP_WAIT_LONG;
		PATTERNS[118] <= OP_LED_RED;
		PATTERNS[119] <= OP_WAIT_LONG;
		PATTERNS[120] <= OP_LED_OFF;
		PATTERNS[121] <= OP_WAIT_LONG;
		PATTERNS[122] <= OP_STATE_RESTORE;
		PATTERNS[123] <= OP_HALT;
		
		// 1000 => 5 red fast flashes
		PATTERNS[128] <= OP_LED_OFF;
		PATTERNS[129] <= OP_WAIT_SHORT;
		PATTERNS[130] <= OP_LED_RED;
		PATTERNS[131] <= OP_WAIT_SHORT;
		PATTERNS[132] <= OP_LED_OFF;
		PATTERNS[133] <= OP_WAIT_SHORT;
		PATTERNS[134] <= OP_LED_RED;
		PATTERNS[135] <= OP_WAIT_SHORT;
		PATTERNS[136] <= OP_LED_OFF;
		PATTERNS[137] <= OP_WAIT_SHORT;
		PATTERNS[138] <= OP_LED_RED;
		PATTERNS[139] <= OP_WAIT_SHORT;
		PATTERNS[140] <= OP_LED_OFF;
		PATTERNS[141] <= OP_WAIT_SHORT;
		PATTERNS[142] <= OP_LED_RED;
		PATTERNS[143] <= OP_WAIT_SHORT;
		PATTERNS[144] <= OP_LED_OFF;
		PATTERNS[145] <= OP_WAIT_SHORT;
		PATTERNS[146] <= OP_LED_RED;
		PATTERNS[147] <= OP_WAIT_SHORT;
		PATTERNS[148] <= OP_LED_OFF;
		PATTERNS[149] <= OP_WAIT_SHORT;
		PATTERNS[150] <= OP_STATE_RESTORE;
		PATTERNS[151] <= OP_HALT;
		
		// 1010 => 5 green fast flashes
		PATTERNS[160] <= OP_LED_OFF;
		PATTERNS[161] <= OP_WAIT_SHORT;
		PATTERNS[162] <= OP_LED_GREEN;
		PATTERNS[163] <= OP_WAIT_SHORT;
		PATTERNS[164] <= OP_LED_OFF;
		PATTERNS[165] <= OP_WAIT_SHORT;
		PATTERNS[166] <= OP_LED_GREEN;
		PATTERNS[167] <= OP_WAIT_SHORT;
		PATTERNS[168] <= OP_LED_OFF;
		PATTERNS[169] <= OP_WAIT_SHORT;
		PATTERNS[170] <= OP_LED_GREEN;
		PATTERNS[171] <= OP_WAIT_SHORT;
		PATTERNS[172] <= OP_LED_OFF;
		PATTERNS[173] <= OP_WAIT_SHORT;
		PATTERNS[174] <= OP_LED_GREEN;
		PATTERNS[175] <= OP_WAIT_SHORT;
		PATTERNS[176] <= OP_LED_OFF;
		PATTERNS[177] <= OP_WAIT_SHORT;
		PATTERNS[178] <= OP_LED_GREEN;
		PATTERNS[179] <= OP_WAIT_SHORT;
		PATTERNS[180] <= OP_LED_OFF;
		PATTERNS[181] <= OP_WAIT_SHORT;
		PATTERNS[182] <= OP_STATE_RESTORE;
		PATTERNS[183] <= OP_HALT;
	end
	
	always @(posedge clk) begin
		if(rst) begin
			pc <= {pattern, 4'b0000};
			tc <= 32'b0;
			busy <= 1;
			led_save_state <= led;
		end else if (busy) begin
			if (tc != 0) begin
				tc <= tc - 1;
			end else begin
				case (PATTERNS[pc])
					OP_LED_OFF: led <= {LED_OFF, LED_OFF};
					OP_LED_GREEN: led <= {LED_OFF, LED_ON};
					OP_LED_RED: led <= {LED_ON, LED_OFF};
					OP_LED_YELLOW: led <= {LED_ON, LED_ON};
					OP_WAIT_SHORT: tc <= SHORT_INTERVAL_TICKS;
					OP_WAIT_LONG: tc <= LONG_INTERVAL_TICKS;
					OP_STATE_SAVE: led_save_state <= led;
					OP_STATE_RESTORE: led <= led_save_state;
					OP_HALT: busy <= 0;
				endcase
				
				pc = pc + 8'b00000001;
			end
		end
	end
endmodule