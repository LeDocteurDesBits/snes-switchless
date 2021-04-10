module d4_patch(
  input in,
  input [7:0] pa,
  input pardn,
  input en,
  output out);

  assign out = (en & !pardn & (pa == 8'h3f)) ? in : 1'bz;
endmodule