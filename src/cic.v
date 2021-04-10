module cic(
	inout d0,
	inout d1,
	input clk,
	input rst,
	input seed,
	input lock,
	output start,
	output rst_host,
	output reg dead);
	
	parameter D413 = 1'b0;
	
	wire [5:0] b;
	
	reg [3:0] a;
	reg [3:0] x;
	reg [1:0] bm;
	reg [3:0] bl;
	reg c;
	reg [9:0] pc;
	reg [9:0] stack [0:3];
	reg [1:0] sp;
	reg [3:0] ram [0:31];
	reg [7:0] rom [0:511];
	reg skip_flag;
	reg transfer_flag;
	reg [1:0] tmp_pc;
	reg [3:0] r [0:3];
	reg d0_oe;
	reg d1_oe;
	
	integer i;
	
	function automatic [9:0] increment_pc(input [9:0] pc);
		begin
			increment_pc = {pc[9:7], ~(pc[1] ^ pc[0]), pc[6:1]};
		end
	endfunction
	
	task init;
		begin
			a <= 4'b0;
			x <= 4'b0;
			bm <= 2'b0;
			bl <= 4'b0;
			c <= 0;
			pc <= 10'b0;
			sp <= 2'b0;
			skip_flag <= 0;
			transfer_flag <= 0;
			tmp_pc <= 2'b0;
			
			for (i = 0 ; i < 32 ; i = i + 1) begin
			 ram[i] <= 4'b0;
			end
			
			for (i = 0 ; i < 4 ; i = i + 1) begin
			 r[i] <= 4'b0;
			 stack[i] <= 10'b0;
			end
			
			d0_oe <= 1; // Output on reset
			d1_oe <= 0; // Input on reset
			dead <= 0;
		end
	endtask
	
	initial begin
		rom[0] = 8'h00;
		rom[1] = 8'h80;
		rom[2] = 8'h78;
		rom[3] = 8'hcb;
		rom[4] = 8'h21;
		rom[5] = 8'h00;
		rom[6] = 8'h46;
		rom[7] = 8'h27;
		rom[8] = 8'h00;
		rom[9] = 8'h35;
		rom[10] = 8'h00;
		rom[11] = 8'hd3;
		rom[12] = 8'h75;
		rom[13] = 8'h31;
		rom[14] = 8'h7c;
		rom[15] = 8'h4a;
		rom[16] = 8'h21;
		rom[17] = 8'h00;
		rom[18] = 8'ha1;
		rom[19] = 8'h30;
		rom[20] = 8'hc1;
		rom[21] = 8'h00;
		rom[22] = 8'h01;
		rom[23] = 8'h70;
		rom[24] = 8'h00;
		rom[25] = 8'hd4;
		rom[26] = 8'h21;
		rom[27] = 8'h41;
		rom[28] = 8'h46;
		rom[29] = 8'h00;
		rom[30] = 8'h34;
		rom[31] = 8'h70;
		rom[32] = 8'h20;
		rom[33] = 8'h30;
		rom[34] = 8'h00;
		rom[35] = 8'h34;
		rom[36] = 8'h9b;
		rom[37] = 8'hfa;
		rom[38] = 8'h48;
		rom[39] = 8'h30;
		rom[40] = 8'hc1;
		rom[41] = 8'h93;
		rom[42] = 8'h00;
		rom[43] = 8'h00;
		rom[44] = 8'h00;
		rom[45] = 8'h5d;
		rom[46] = 8'h79;
		rom[47] = 8'h21;
		rom[48] = 8'he1;
		rom[49] = 8'h00;
		rom[50] = 8'h67;
		rom[51] = 8'h00;
		rom[52] = 8'h01;
		rom[53] = 8'h46;
		rom[54] = 8'h3d;
		rom[55] = 8'h2e;
		rom[56] = 8'h30;
		rom[57] = 8'h00;
		rom[58] = 8'h46;
		rom[59] = 8'h21;
		rom[60] = 8'hfd;
		rom[61] = 8'h62;
		rom[62] = 8'h31;
		rom[63] = 8'h46;
		rom[64] = 8'h7c;
		rom[65] = 8'h33;
		rom[66] = 8'he4;
		rom[67] = 8'h3c;
		rom[68] = 8'h00;
		rom[69] = 8'h4c;
		rom[70] = 8'h21;
		rom[71] = 8'h46;
		rom[72] = 8'h46;
		rom[73] = 8'h73;
		rom[74] = 8'h7d;
		rom[75] = 8'h20;
		rom[76] = 8'h00;
		rom[77] = 8'h2b;
		rom[78] = 8'h4c;
		rom[79] = 8'h43;
		rom[80] = 8'h46;
		rom[81] = 8'h4a;
		rom[82] = 8'h42;
		rom[83] = 8'h5d;
		rom[84] = 8'h33;
		rom[85] = 8'h00;
		rom[86] = 8'h00;
		rom[87] = 8'h46;
		rom[88] = 8'h00;
		rom[89] = 8'h00;
		rom[90] = 8'hb4;
		rom[91] = 8'h38;
		rom[92] = 8'h42;
		rom[93] = 8'h46;
		rom[94] = 8'h32;
		rom[95] = 8'h55;
		rom[96] = 8'h27;
		rom[97] = 8'h01;
		rom[98] = 8'h00;
		rom[99] = 8'h74;
		rom[100] = 8'h00;
		rom[101] = 8'h55;
		rom[102] = 8'h00;
		rom[103] = 8'h55;
		rom[104] = 8'h75;
		rom[105] = 8'h30;
		rom[106] = 8'h20;
		rom[107] = 8'h00;
		rom[108] = 8'hae;
		rom[109] = 8'h42;
		rom[110] = 8'hb8;
		rom[111] = 8'h67;
		rom[112] = 8'h30;
		rom[113] = 8'h2b;
		rom[114] = 8'h00;
		rom[115] = 8'h66;
		rom[116] = 8'h21;
		rom[117] = 8'h30;
		rom[118] = 8'h31;
		rom[119] = 8'hf6;
		rom[120] = 8'h23;
		rom[121] = 8'hde;
		rom[122] = 8'h30;
		rom[123] = 8'h75;
		rom[124] = 8'h46;
		rom[125] = 8'h21;
		rom[126] = 8'h20;
		rom[127] = 8'h80;
		rom[128] = 8'h00;
		rom[129] = 8'h80;
		rom[130] = 8'h80;
		rom[131] = 8'hbd;
		rom[132] = 8'hbf;
		rom[133] = 8'h00;
		rom[134] = 8'hd7;
		rom[135] = 8'h61;
		rom[136] = 8'h55;
		rom[137] = 8'h10;
		rom[138] = 8'h00;
		rom[139] = 8'h00;
		rom[140] = 8'h23;
		rom[141] = 8'h60;
		rom[142] = 8'hd9;
		rom[143] = 8'ha1;
		rom[144] = 8'hdf;
		rom[145] = 8'h00;
		rom[146] = 8'h5d;
		rom[147] = 8'h55;
		rom[148] = 8'h5d;
		rom[149] = 8'h00;
		rom[150] = 8'h00;
		rom[151] = 8'h46;
		rom[152] = 8'h7d;
		rom[153] = 8'h4a;
		rom[154] = 8'hd9;
		rom[155] = 8'h23;
		rom[156] = 8'h46;
		rom[157] = 8'h7c;
		rom[158] = 8'h01;
		rom[159] = 8'h7c;
		rom[160] = 8'hd9;
		rom[161] = 8'h5d;
		rom[162] = 8'h00;
		rom[163] = 8'h20;
		rom[164] = 8'h6c;
		rom[165] = 8'h46;
		rom[166] = 8'h5c;
		rom[167] = 8'h00;
		rom[168] = 8'hf5;
		rom[169] = 8'h68;
		rom[170] = 8'h00;
		rom[171] = 8'h74;
		rom[172] = 8'h7d;
		rom[173] = 8'h00;
		rom[174] = 8'h41;
		rom[175] = 8'hdd;
		rom[176] = 8'h7c;
		rom[177] = 8'h74;
		rom[178] = 8'h47;
		rom[179] = 8'h4c;
		rom[180] = 8'h4c;
		rom[181] = 8'h7c;
		rom[182] = 8'h40;
		rom[183] = 8'h7d;
		rom[184] = 8'hf0;
		rom[185] = 8'h41;
		rom[186] = 8'hb0;
		rom[187] = 8'hd7;
		rom[188] = 8'hd7;
		rom[189] = 8'h5d;
		rom[190] = 8'hcb;
		rom[191] = 8'h5c;
		rom[192] = 8'h30;
		rom[193] = 8'h7c;
		rom[194] = 8'hfe;
		rom[195] = 8'hd7;
		rom[196] = 8'h21;
		rom[197] = 8'h00;
		rom[198] = 8'h55;
		rom[199] = 8'h7c;
		rom[200] = 8'h20;
		rom[201] = 8'h41;
		rom[202] = 8'h41;
		rom[203] = 8'h00;
		rom[204] = 8'hfa;
		rom[205] = 8'h41;
		rom[206] = 8'h00;
		rom[207] = 8'hb1;
		rom[208] = 8'h60;
		rom[209] = 8'h64;
		rom[210] = 8'h64;
		rom[211] = 8'h47;
		rom[212] = 8'h61;
		rom[213] = 8'h4c;
		rom[214] = 8'hfa;
		rom[215] = 8'h78;
		rom[216] = 8'hd9;
		rom[217] = 8'h75;
		rom[218] = 8'h20;
		rom[219] = 8'hf0;
		rom[220] = 8'h7d;
		rom[221] = 8'h30;
		rom[222] = 8'h65;
		rom[223] = 8'h74;
		rom[224] = 8'h21;
		rom[225] = 8'hbd;
		rom[226] = 8'h4c;
		rom[227] = 8'h4a;
		rom[228] = 8'h4a;
		rom[229] = 8'h55;
		rom[230] = 8'h75;
		rom[231] = 8'h55;
		rom[232] = 8'hfa;
		rom[233] = 8'h21;
		rom[234] = 8'hc1;
		rom[235] = 8'h4b;
		rom[236] = 8'h61;
		rom[237] = 8'h27;
		rom[238] = 8'hf0;
		rom[239] = 8'h7d;
		rom[240] = 8'h46;
		rom[241] = 8'h7d;
		rom[242] = 8'h30;
		rom[243] = 8'h64;
		rom[244] = 8'hd7;
		rom[245] = 8'h60;
		rom[246] = 8'hfa;
		rom[247] = 8'hcb;
		rom[248] = 8'h80;
		rom[249] = 8'hde;
		rom[250] = 8'h00;
		rom[251] = 8'h75;
		rom[252] = 8'hfc;
		rom[253] = 8'h7d;
		rom[254] = 8'h31;
		rom[255] = 8'h80;
		rom[256] = 8'h00;
		rom[257] = 8'h80;
		rom[258] = 8'h78;
		rom[259] = 8'h74;
		rom[260] = 8'h42;
		rom[261] = 8'hfe;
		rom[262] = 8'h00;
		rom[263] = 8'h00;
		rom[264] = 8'h31;
		rom[265] = 8'h39;
		rom[266] = 8'h78;
		rom[267] = 8'h42;
		rom[268] = 8'h00;
		rom[269] = 8'h6a;
		rom[270] = 8'hc8;
		rom[271] = 8'h42;
		rom[272] = 8'h75;
		rom[273] = 8'h36;
		rom[274] = 8'h42;
		rom[275] = 8'h3d;
		rom[276] = 8'h31;
		rom[277] = 8'h41;
		rom[278] = 8'h3f;
		rom[279] = 8'h00;
		rom[280] = 8'h3b;
		rom[281] = 8'h68;
		rom[282] = 8'h65;
		rom[283] = 8'h3f;
		rom[284] = 8'h42;
		rom[285] = 8'h7c;
		rom[286] = 8'h3f;
		rom[287] = 8'h60;
		rom[288] = 8'h3b;
		rom[289] = 8'h41;
		rom[290] = 8'h42;
		rom[291] = 8'hda;
		rom[292] = 8'h36;
		rom[293] = 8'h3e;
		rom[294] = 8'h3a;
		rom[295] = 8'h42;
		rom[296] = 8'h69;
		rom[297] = 8'h3c;
		rom[298] = 8'h3c;
		rom[299] = 8'h3e;
		rom[300] = 8'h3d;
		rom[301] = 8'h37;
		rom[302] = 8'h6b;
		rom[303] = 8'h7c;
		rom[304] = 8'h21;
		rom[305] = 8'h42;
		rom[306] = 8'h65;
		rom[307] = 8'h30;
		rom[308] = 8'h35;
		rom[309] = 8'hda;
		rom[310] = 8'h42;
		rom[311] = 8'h42;
		rom[312] = 8'h3b;
		rom[313] = 8'h3a;
		rom[314] = 8'h30;
		rom[315] = 8'hda;
		rom[316] = 8'h61;
		rom[317] = 8'h42;
		rom[318] = 8'h31;
		rom[319] = 8'h21;
		rom[320] = 8'h78;
		rom[321] = 8'h21;
		rom[322] = 8'h38;
		rom[323] = 8'h83;
		rom[324] = 8'h42;
		rom[325] = 8'h31;
		rom[326] = 8'h7c;
		rom[327] = 8'h34;
		rom[328] = 8'h22;
		rom[329] = 8'h42;
		rom[330] = 8'h42;
		rom[331] = 8'h7c;
		rom[332] = 8'h31;
		rom[333] = 8'h42;
		rom[334] = 8'h31;
		rom[335] = 8'h30;
		rom[336] = 8'h42;
		rom[337] = 8'h65;
		rom[338] = 8'h42;
		rom[339] = 8'h38;
		rom[340] = 8'h00;
		rom[341] = 8'h42;
		rom[342] = 8'h42;
		rom[343] = 8'hc8;
		rom[344] = 8'h3f;
		rom[345] = 8'h42;
		rom[346] = 8'h42;
		rom[347] = 8'h38;
		rom[348] = 8'h42;
		rom[349] = 8'h65;
		rom[350] = 8'h30;
		rom[351] = 8'h31;
		rom[352] = 8'h80;
		rom[353] = 8'h75;
		rom[354] = 8'h3e;
		rom[355] = 8'h42;
		rom[356] = 8'h39;
		rom[357] = 8'hda;
		rom[358] = 8'h42;
		rom[359] = 8'h7c;
		rom[360] = 8'h31;
		rom[361] = 8'h42;
		rom[362] = 8'h7c;
		rom[363] = 8'h31;
		rom[364] = 8'h41;
		rom[365] = 8'h37;
		rom[366] = 8'h35;
		rom[367] = 8'h63;
		rom[368] = 8'h7d;
		rom[369] = 8'h36;
		rom[370] = 8'h42;
		rom[371] = 8'hc8;
		rom[372] = 8'h42;
		rom[373] = 8'h62;
		rom[374] = 8'h7c;
		rom[375] = 8'h30;
		rom[376] = 8'hfa;
		rom[377] = 8'h31;
		rom[378] = 8'h34;
		rom[379] = 8'h7c;
		rom[380] = 8'he1;
		rom[381] = 8'hc8;
		rom[382] = 8'h75;
		rom[383] = 8'h80;
		rom[384] = 8'h00;
		rom[385] = 8'h80;
		rom[386] = 8'h78;
		rom[387] = 8'h69;
		rom[388] = 8'h00;
		rom[389] = 8'h00;
		rom[390] = 8'hd0;
		rom[391] = 8'h42;
		rom[392] = 8'h00;
		rom[393] = 8'h00;
		rom[394] = 8'h00;
		rom[395] = 8'h00;
		rom[396] = 8'h20;
		rom[397] = 8'h64;
		rom[398] = 8'h72;
		rom[399] = 8'hf4;
		rom[400] = 8'h00;
		rom[401] = 8'h00;
		rom[402] = 8'h00;
		rom[403] = 8'h00;
		rom[404] = 8'h00;
		rom[405] = 8'h00;
		rom[406] = 8'h00;
		rom[407] = 8'hef;
		rom[408] = 8'h00;
		rom[409] = 8'h40;
		rom[410] = 8'h20;
		rom[411] = 8'h00;
		rom[412] = 8'h00;
		rom[413] = 8'h08;
		rom[414] = 8'h67;
		rom[415] = 8'h52;
		rom[416] = 8'h4c;
		rom[417] = 8'h00;
		rom[418] = 8'h00;
		rom[419] = 8'h37;
		rom[420] = 8'h00;
		rom[421] = 8'h00;
		rom[422] = 8'h00;
		rom[423] = 8'h00;
		rom[424] = 8'h30;
		rom[425] = 8'h00;
		rom[426] = 8'h00;
		rom[427] = 8'h00;
		rom[428] = 8'h00;
		rom[429] = 8'h00;
		rom[430] = 8'h4c;
		rom[431] = 8'h4a;
		rom[432] = 8'h72;
		rom[433] = 8'h00;
		rom[434] = 8'h57;
		rom[435] = 8'h00;
		rom[436] = 8'h00;
		rom[437] = 8'h55;
		rom[438] = 8'h00;
		rom[439] = 8'h00;
		rom[440] = 8'h00;
		rom[441] = 8'h00;
		rom[442] = 8'h42;
		rom[443] = 8'h5d;
		rom[444] = 8'h42;
		rom[445] = 8'h55;
		rom[446] = 8'h4a;
		rom[447] = 8'h2f;
		rom[448] = 8'h78;
		rom[449] = 8'h00;
		rom[450] = 8'h00;
		rom[451] = 8'h01;
		rom[452] = 8'h00;
		rom[453] = 8'h00;
		rom[454] = 8'h4a;
		rom[455] = 8'h4d;
		rom[456] = 8'h00;
		rom[457] = 8'h00;
		rom[458] = 8'h00;
		rom[459] = 8'h5d;
		rom[460] = 8'h00;
		rom[461] = 8'h00;
		rom[462] = 8'h00;
		rom[463] = 8'h72;
		rom[464] = 8'h68;
		rom[465] = 8'h60;
		rom[466] = 8'h00;
		rom[467] = 8'h00;
		rom[468] = 8'h4a;
		rom[469] = 8'h00;
		rom[470] = 8'h00;
		rom[471] = 8'h52;
		rom[472] = 8'h4a;
		rom[473] = 8'h00;
		rom[474] = 8'h00;
		rom[475] = 8'h00;
		rom[476] = 8'h00;
		rom[477] = 8'h0f;
		rom[478] = 8'h70;
		rom[479] = 8'h40;
		rom[480] = 8'h80;
		rom[481] = 8'h00;
		rom[482] = 8'h00;
		rom[483] = 8'h00;
		rom[484] = 8'h00;
		rom[485] = 8'h5c;
		rom[486] = 8'h00;
		rom[487] = 8'h54;
		rom[488] = 8'h6a;
		rom[489] = 8'h00;
		rom[490] = 8'h23;
		rom[491] = 8'h49;
		rom[492] = 8'h52;
		rom[493] = 8'h00;
		rom[494] = 8'h00;
		rom[495] = 8'h5c;
		rom[496] = 8'h74;
		rom[497] = 8'h00;
		rom[498] = 8'h00;
		rom[499] = 8'h42;
		rom[500] = 8'h4c;
		rom[501] = 8'h72;
		rom[502] = 8'hc3;
		rom[503] = 8'h48;
		rom[504] = 8'h7d;
		rom[505] = 8'h73;
		rom[506] = 8'h20;
		rom[507] = 8'h21;
		rom[508] = 8'hbf;
		rom[509] = 8'h72;
		rom[510] = 8'h75;
		rom[511] = 8'h80;
		
		if (D413) begin
			rom[356] = 8'h36;
		end
		
		init();
	end
	
	always @(posedge clk) begin
		if (rst) begin
			init();
		end else if (transfer_flag) begin
			pc <= {tmp_pc, rom[pc]};
			transfer_flag <= 0;
		end else if (!skip_flag) begin
			casex (rom[pc])
				// ADX
				8'h0x: {skip_flag, a} <= a + rom[pc][3:0];
				
				// TAX
				8'h1x: skip_flag <= (a == rom[pc][3:0]);
				
				// LBLX
				8'h2x: bl <= rom[pc][3:0];
				
				// LAX
				8'h3x: a <= rom[pc][3:0]; // Should skip if "last instruction is LAX" but the code doesn't make sense then...
				
				// LDA
				8'h40: a <= ram[b];
				
				// EXC
				8'h41: begin
					a <= ram[b];
					ram[b] <= a;
				end
				
				// EXCI
				8'h42: begin
					a <= ram[b];
					ram[b] <= a;
					{skip_flag, bl} <= bl + 4'b0001;
				end
				
				// EXCD
				8'h43: begin
					a <= ram[b];
					ram[b] <= a;
					bl <= bl - 4'b0001;
					skip_flag <= (bl == 4'b0000);
				end
				
				// NEGA
				8'h44: begin
					a <= ~a + 4'b0001;
				end
				
				// ATR
				8'h46: begin
					r[bl] = a;
					d0_oe = (bl == 4'b0000) && a[0];
					d1_oe = (bl == 4'b0000) && a[1];
				end
				
				// MTR
				8'h47: begin
					r[bl] = ram[b];
					d0_oe = (bl == 4'b0000) && ram[b][0];
					d1_oe = (bl == 4'b0000) && ram[b][1];
				end
				
				// SC
				8'h48: begin
					c <= 1;
				end
				
				// RC
				8'h49: begin
					c <= 0;
				end
				
				// STR
				8'h4a: begin
					ram[b] <= a;
				end
				
				// RTN
				8'h4c: begin
					pc <= stack[sp - 2'b01];
					sp <= sp - 2'b01;
				end
				
				// RTNS
				8'h4d: begin
					pc <= stack[sp - 2'b01];
					sp <= sp - 2'b01;
					skip_flag <= 1;
				end
				
				// INBL
				8'h52: begin
					a <= ram[b];
					{skip_flag, bl} <= bl + 4'b0001;
				end
				
				// COMA
				8'h54: begin
					a <= ~a;
				end
				
				// RTA
				8'h55: begin
					if (bl == 4'b0000) begin
						//d0_oe = 0;
						//d1_oe = 0;
						a <= {lock, seed, d1 | r[0][1], d0 | r[0][0]};
					end else begin
						a <= r[bl];
					end
				end
				
				// XBLA
				8'h57: begin
					a <= bl;
					bl <= a;
				end
				
				// ATX
				8'h5c: begin
					x <= a;
				end
				
				// EXAX
				8'h5d: begin
					a <= x;
					x <= a;
				end
				
				// HACK: Prevent Quartus Prime from crashing
				8'b0110_0000: skip_flag <= ram[b][0];
				8'b0110_0001: skip_flag <= ram[b][1];
				8'b0110_0010: skip_flag <= ram[b][2];
				8'b0110_0011: skip_flag <= ram[b][3];
				
				// HACK: Prevent Quartus Prime from crashing
				8'b0110_0100: skip_flag <= a[0];
				8'b0110_0101: skip_flag <= a[1];
				8'b0110_0110: skip_flag <= a[2];
				8'b0110_0111: skip_flag <= a[3];
				
				// HACK: Prevent Quartus Prime from crashing
				8'b0110_1000: ram[b][0] <= 0;
				8'b0110_1001: ram[b][1] <= 0;
				8'b0110_1010: ram[b][2] <= 0;
				8'b0110_1011: ram[b][3] <= 0;
				
				// HACK: Prevent Quartus Prime from crashing
				8'b0110_1100: ram[b][0] <= 1;
				8'b0110_1101: ram[b][1] <= 1;
				8'b0110_1110: ram[b][2] <= 1;
				8'b0110_1111: ram[b][3] <= 1;
				
				// ADD
				8'h70: begin
					a <= a + ram[b];
				end
				
				// ADS
				8'h71: {skip_flag, a} <= a + ram[b];
				
				// ADC
				8'h72: begin
					a <= a + ram[b] + c; // c should be updated according to SHARP's documentation
				end
				
				// ADCS
				8'h73: begin
					{skip_flag, a} <= a + ram[b] + c; // c should be updated according to SHARP's documentation
				end
				
				// LBMX
				8'b0111_01xx: begin
					bm <= rom[pc][1:0];
				end
				
				// TL
				8'b0111_10xx: begin
					tmp_pc <= rom[pc][1:0];
					transfer_flag <= 1;
				end
				
				// TLS
				8'b0111_11xx: begin
					stack[sp] <= increment_pc(increment_pc(pc));
					sp <= sp + 2'b01;
					tmp_pc <= rom[pc][1:0];
					transfer_flag <= 1;
				end
				
				// TR
				8'b1xxx_xxxx: begin
					pc <= {pc[9:7], rom[pc][6:0]};
					
					if ({pc[9:7], rom[pc][6:0]} == 10'b0011010111) begin // 0xd7
					   dead <= 1;
					end
				end
			endcase
			
			if ((rom[pc] != 8'h4c) && (rom[pc] != 8'h4d) && !rom[pc][7]) begin
				pc <= increment_pc(pc);
			end
		end else begin
		    pc <= increment_pc(pc);
			skip_flag <= 0;
		end
	end
	
	assign b = {bm, bl};
	assign d0 = (d0_oe && !dead) ? r[0][0] : 1'bz;
	assign d1 = (d1_oe && !dead) ? r[0][1] : 1'bz;
	assign start = !dead && r[1][1];
	assign rst_host = !dead && !r[1][0]; // The CIC uses a negative logic reset so we invert the value here.
endmodule