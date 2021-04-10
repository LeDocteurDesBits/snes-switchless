module uigr(
	input gamepad_data,
	input gamepad_clk,
	input gamepad_latch,
	input reset_button,
	input clk,
	output reg [1:0] region,
	output reg d4_en,
	output reg region_timeout_en,
	output [1:0] led,
	output cic_reset);
	
	// 1.2s @50Hz, 1s @60Hz
	parameter LONG_RESET_TICKS = 16 * 60;
	
	// 300ms @50Hz, 250ms @60Hz
	parameter LOW_TIMEOUT_TICKS = 16 * 60 / 4;
	
	/*
	 * 15 (MSB)                                                                      (LSB) 0
	 * +---+---+---+---+---+---+---+---+-------+------+------+----+-------+--------+---+---+
	 * | . | . | . | . | R | L | X | A | Right | Left | Down | Up | Start | Select | Y | B |
	 * +---+---+---+---+---+---+---+---+-------+------+------+----+-------+--------+---+---+
	 */
	localparam INPUT_FORCE_50HZ = 				16'b0000110000000110; // L + R + Select + Y
	localparam INPUT_FORCE_60HZ = 				16'b0000110100000100; // L + R + Select + A
	localparam INPUT_FORCE_CARTRIDGE_REGION = 16'b0000110000000101; // L + R + Select + B
	localparam INPUT_RESET =						16'b0000110000001100; // L + R + Select + Start
	localparam INPUT_LONG_RESET =				16'b0000111000000100; // L + R + Select + X
	localparam INPUT_TOGGLE_REGION_TIMEOUT =	16'b0000110000010100; // L + R + Select + Up
	localparam INPUT_TOGGLE_D4_PATCH =			16'b0000110000100100; // L + R + Select + Down
	localparam INPUT_TOGGLE_LOCK =				16'b0000111101010000; // L + R + Up + Left + X + A
	localparam INPUT_HARD_LOCK =					16'b0000110101100001; // L + R + Down + Left + A + B
	
	localparam STATE_RESET_IDLE = 				2'b00;
	localparam STATE_RESET_COUNTING = 			2'b01;
	localparam STATE_RESET_WAITING_LOW = 		2'b10;
	localparam STATE_RESET_WAITING_TIMEOUT = 	2'b11;
	
	localparam REGION_60HZ = 		2'b00;
	localparam REGION_50HZ = 		2'b01;
	localparam REGION_CARTRIDGE = 2'b10;
	
	localparam LED_DRIVER_PATTERN_50HZ = 					4'b0001;
	localparam LED_DRIVER_PATTERN_60HZ = 					4'b0010;
	localparam LED_DRIVER_PATTERN_CARTRIDGE = 			4'b0011;
	localparam LED_DRIVER_PATTERN_REGION_TIMEOUT_ON = 	4'b0100;
	localparam LED_DRIVER_PATTERN_REGION_TIMEOUT_OFF = 4'b0101;
	localparam LED_DRIVER_PATTERN_D4_PATCH_ON = 			4'b0110;
	localparam LED_DRIVER_PATTERN_D4_PATCH_OFF = 		4'b0111;
	localparam LED_DRIVER_PATTERN_LOCKED = 				4'b1000;
	localparam LED_DRIVER_PATTERN_UNLOCKED = 				4'b1010;
	
	localparam RESET_DRIVER_PATTERN_SHORT_RESET = 	0;
	localparam RESET_DRIVER_PATTERN_LONG_RESET = 	1;
	
	wire reset_button_debounced;
	wire led_driver_busy;
	wire reset_driver_busy;
	
	reg [15:0] current_input;
	reg [15:0] previous_input;
	reg [3:0] shift_counter;
	reg locked;
	reg hard_locked;
	
	reg [1:0] reset_state;
	reg [31:0] reset_counter;
	reg reset_double_flag;
	reg [1:0] reset_preselected_region;
	
	reg [3:0] led_driver_pattern;
	reg led_driver_rst;
	
	reg reset_driver_pattern;
	reg reset_driver_rst;
	
	uigr_led_driver led_driver(
		.pattern(led_driver_pattern),
		.rst(led_driver_rst),
		.clk(clk),
		.led(led),
		.busy(led_driver_busy)
	);
	
	uigr_reset_driver reset_driver(
		.pattern(reset_driver_pattern),
		.rst(reset_driver_rst),
		.clk(clk),
		.out(cic_reset),
		.busy(reset_driver_busy)
	);
	
	// 500 000 ticks (10ms @50MHz), invert output
	debouncer #(500_000, 1) debouncer(
		.in(reset_button),
		.clk(clk),
		.out(reset_button_debounced)
	);
	
	initial begin
		current_input <= 16'b0;
		previous_input <= 16'b0;
		shift_counter <= 4'b0;
		
		reset_state <= STATE_RESET_IDLE;
		reset_counter <= 32'b0;
		reset_double_flag <= 0;
		
		led_driver_pattern <= 4'b0;
		led_driver_rst <= 0;
		
		reset_driver_pattern <= 0;
		reset_driver_rst <= 0;
		
		// uIGR Defaults:
		// 	* Unlocked
		// 	* Region set to "cartridge region"
		// 	* D4 patch enabled
		//		* Region timeout disabled
		locked <= 0;
		hard_locked <= 0;
		region <= 2'b10;
		d4_en <= 1;
		region_timeout_en <= 0;
	end
	
	always @(posedge gamepad_latch or negedge gamepad_clk) begin
		if (gamepad_latch) begin
			current_input <= 16'b0;
			shift_counter <= 4'b0;
			led_driver_rst <= 0;
			reset_driver_rst <= 0;
		end else begin
			shift_counter = shift_counter + 4'b0001;
			current_input = {~gamepad_data, current_input[15:1]};
			
			case (reset_state)
				STATE_RESET_IDLE: begin
					if (reset_button_debounced && !reset_driver_busy) begin
						reset_counter <= 32'b0;
						reset_double_flag <= 0;
						reset_state <= STATE_RESET_COUNTING;
					end
				end
				
				STATE_RESET_COUNTING: begin
					if (!reset_button_debounced) begin
						if (!reset_double_flag) begin
							reset_counter <= 32'b0;
							reset_state <= STATE_RESET_WAITING_TIMEOUT;
						end else begin
							reset_driver_pattern <= 1;
							reset_driver_rst <= 1;
							reset_state <= STATE_RESET_IDLE;
						end
					end else begin
						reset_counter <= reset_counter + 1;
						
						if (reset_counter >= LONG_RESET_TICKS) begin
							reset_preselected_region <= region;
							reset_state <= STATE_RESET_WAITING_LOW;
							hard_locked <= 1; // Locking the gamepad to prevent a concurrent region change
						end
					end
				end
				
				STATE_RESET_WAITING_LOW: begin
					if (!reset_button_debounced) begin
						reset_state <= STATE_RESET_IDLE;
						region <= reset_preselected_region;
						hard_locked <= 0; // Unlocking the gamepad
					end else begin
						reset_counter <= reset_counter + 1;
						
						if (reset_counter >= LONG_RESET_TICKS) begin
							reset_counter <= 32'b0;
							
							case (reset_preselected_region)
								REGION_50HZ: begin
									reset_preselected_region <= REGION_60HZ;
									led_driver_pattern = LED_DRIVER_PATTERN_60HZ;
									led_driver_rst <= 1;
								end
								
								REGION_60HZ: begin
									reset_preselected_region <= REGION_CARTRIDGE;
									led_driver_pattern <= LED_DRIVER_PATTERN_CARTRIDGE;
									led_driver_rst <= 1;
								end
								
								REGION_CARTRIDGE: begin
									reset_preselected_region <= REGION_50HZ;
									led_driver_pattern <= LED_DRIVER_PATTERN_50HZ;
									led_driver_rst <= 1;
								end
							endcase
						end
					end
				end
				
				STATE_RESET_WAITING_TIMEOUT: begin
					if (!reset_button_debounced) begin
						reset_counter <= reset_counter + 1;
						
						if (reset_counter >= LOW_TIMEOUT_TICKS) begin
							reset_driver_pattern <= 0;
							reset_driver_rst <= 1;
							reset_state <= STATE_RESET_IDLE;
						end
					end else begin
						reset_double_flag <= 1;
						reset_counter <= 32'b0;
						reset_state <= STATE_RESET_COUNTING;
					end
				end
			endcase
			
			if ((shift_counter == 4'b0) && (current_input != previous_input)) begin
				previous_input <= current_input;
				
				// To handle the gamepad input, we must ensure that :
				// 	1. The led driver is not in the reset state
				// 	2. The led driver is not busy
				// 	3. The user hasn't hardlocked the uIGR
				// 	4. The user hasn't locked the uIGR and the input is not the unlock command
				if (!led_driver_rst && !led_driver_busy && !hard_locked && (!locked || (current_input == INPUT_TOGGLE_LOCK))) begin
					case (current_input)
						INPUT_FORCE_50HZ: begin
							region <= REGION_50HZ;
							led_driver_pattern <= LED_DRIVER_PATTERN_50HZ;
							led_driver_rst <= 1;
						end
						
						INPUT_FORCE_60HZ: begin
							region <= REGION_60HZ;
							led_driver_pattern <= LED_DRIVER_PATTERN_60HZ;
							led_driver_rst <= 1;
						end
						
						INPUT_FORCE_CARTRIDGE_REGION: begin
							region <= REGION_CARTRIDGE;
							led_driver_pattern <= LED_DRIVER_PATTERN_CARTRIDGE;
							led_driver_rst <= 1;
						end
						
						INPUT_RESET: begin
							reset_driver_pattern <= 0;
							reset_driver_rst <= 1;
						end
						
						INPUT_LONG_RESET: begin
							reset_driver_pattern <= 1;
							reset_driver_rst <= 1;
						end
						
						INPUT_TOGGLE_REGION_TIMEOUT: begin
							region_timeout_en <= ~region_timeout_en;
							led_driver_pattern <= (region_timeout_en) ? LED_DRIVER_PATTERN_REGION_TIMEOUT_OFF : LED_DRIVER_PATTERN_REGION_TIMEOUT_ON;
							led_driver_rst <= 1;
						end
						
						INPUT_TOGGLE_D4_PATCH: begin
							d4_en <= ~d4_en;
							led_driver_pattern <= (d4_en) ? LED_DRIVER_PATTERN_D4_PATCH_OFF : LED_DRIVER_PATTERN_D4_PATCH_ON;
							led_driver_rst <= 1;
						end
						
						INPUT_TOGGLE_LOCK: begin
							locked <= ~locked;
							led_driver_pattern <= (locked) ? LED_DRIVER_PATTERN_UNLOCKED : LED_DRIVER_PATTERN_LOCKED;
							led_driver_rst <= 1;
						end
						
						INPUT_HARD_LOCK: begin
							hard_locked <= 1;
							led_driver_pattern <= LED_DRIVER_PATTERN_LOCKED;
							led_driver_rst <= 1;
						end
					endcase
				end
			end
		end
	end
endmodule