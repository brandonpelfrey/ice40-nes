// This module displays hex values provided on several 8bit
// data ports. They appear as hex values at the top left of
// the output image.
module mod_hex_display(
  input       in_pix_clk,   // Clock to sync all pixel inputs/outputs to
  input [9:0] in_pix_x,     // Current pixel output position (x,y)
  input [9:0] in_pix_y,
  input       in_latch,
  input [7:0] in_data0,     // Input data lines. These are written
  input [7:0] in_data1,     // to internal registers.
  input [7:0] in_data2,
  input [7:0] in_data3,
  input [7:0] in_data4,
  input [7:0] in_data5,
  input [7:0] in_data6,
  input [7:0] in_data7,
  input [7:0] in_pixel_r,   // Parent video pixel data to overlay on
  input [7:0] in_pixel_g,
  input [7:0] in_pixel_b,

  output [7:0] out_pixel_r, // Video pixel data after overlay
  output [7:0] out_pixel_g,
  output [7:0] out_pixel_b
);

// 8x8 font data for hex digits 0-F
reg [7:0] font_data[127:0];
initial begin
font_data[  0] <= { 8'b00000000 };
font_data[  1] <= { 8'b00111100 };
font_data[  2] <= { 8'b01000010 };
font_data[  3] <= { 8'b01000010 };
font_data[  4] <= { 8'b01000010 };
font_data[  5] <= { 8'b01000010 };
font_data[  6] <= { 8'b00111100 };
font_data[  7] <= { 8'b00000000 };
font_data[  8] <= { 8'b00000000 };

font_data[  9] <= { 8'b00001000 };
font_data[ 10] <= { 8'b00011000 };
font_data[ 11] <= { 8'b00001000 };
font_data[ 12] <= { 8'b00001000 };
font_data[ 13] <= { 8'b00001000 };
font_data[ 14] <= { 8'b00011100 };
font_data[ 15] <= { 8'b00000000 };

font_data[ 16] <= { 8'b00000000 };
font_data[ 17] <= { 8'b00111100 };
font_data[ 18] <= { 8'b01000010 };
font_data[ 19] <= { 8'b00000100 };
font_data[ 20] <= { 8'b00011000 };
font_data[ 21] <= { 8'b00100000 };
font_data[ 22] <= { 8'b01111110 };
font_data[ 23] <= { 8'b00000000 };

font_data[ 24] <= { 8'b00000000 };
font_data[ 25] <= { 8'b00111100 };
font_data[ 26] <= { 8'b01000010 };
font_data[ 27] <= { 8'b00001100 };
font_data[ 28] <= { 8'b00000010 };
font_data[ 29] <= { 8'b01000010 };
font_data[ 30] <= { 8'b00111100 };
font_data[ 31] <= { 8'b00000000 };

font_data[ 32] <= { 8'b00000000 };
font_data[ 33] <= { 8'b00000100 };
font_data[ 34] <= { 8'b00001100 };
font_data[ 35] <= { 8'b00010100 };
font_data[ 36] <= { 8'b00100100 };
font_data[ 37] <= { 8'b00111110 };
font_data[ 38] <= { 8'b00000100 };
font_data[ 39] <= { 8'b00000000 };

font_data[ 40] <= { 8'b00000000 };
font_data[ 41] <= { 8'b01111110 };
font_data[ 42] <= { 8'b01000000 };
font_data[ 43] <= { 8'b01111100 };
font_data[ 44] <= { 8'b00000010 };
font_data[ 45] <= { 8'b01000010 };
font_data[ 46] <= { 8'b00111100 };
font_data[ 47] <= { 8'b00000000 };

font_data[ 48] <= { 8'b00000000 };
font_data[ 49] <= { 8'b00111100 };
font_data[ 50] <= { 8'b01000000 };
font_data[ 51] <= { 8'b01111100 };
font_data[ 52] <= { 8'b01000010 };
font_data[ 53] <= { 8'b01000010 };
font_data[ 54] <= { 8'b00111100 };
font_data[ 55] <= { 8'b00000000 };

font_data[ 56] <= { 8'b00000000 };
font_data[ 57] <= { 8'b01111110 };
font_data[ 58] <= { 8'b00000100 };
font_data[ 59] <= { 8'b00001000 };
font_data[ 60] <= { 8'b00010000 };
font_data[ 61] <= { 8'b00100000 };
font_data[ 62] <= { 8'b01000000 };
font_data[ 63] <= { 8'b00000000 };

font_data[ 64] <= { 8'b00000000 };
font_data[ 65] <= { 8'b00111100 };
font_data[ 66] <= { 8'b01000010 };
font_data[ 67] <= { 8'b00111100 };
font_data[ 68] <= { 8'b01000010 };
font_data[ 69] <= { 8'b01000010 };
font_data[ 70] <= { 8'b00111100 };
font_data[ 71] <= { 8'b00000000 };

font_data[ 72] <= { 8'b00000000 };
font_data[ 73] <= { 8'b00111100 };
font_data[ 74] <= { 8'b01000010 };
font_data[ 75] <= { 8'b01000010 };
font_data[ 76] <= { 8'b00111110 };
font_data[ 77] <= { 8'b00000010 };
font_data[ 78] <= { 8'b00111100 };
font_data[ 79] <= { 8'b00000000 };

font_data[ 80] <= { 8'b00000000 };
font_data[ 81] <= { 8'b00111100 };
font_data[ 82] <= { 8'b01000010 };
font_data[ 83] <= { 8'b01111110 };
font_data[ 84] <= { 8'b01000010 };
font_data[ 85] <= { 8'b01000010 };
font_data[ 86] <= { 8'b01000010 };
font_data[ 87] <= { 8'b00000000 };

font_data[ 88] <= { 8'b00000000 };
font_data[ 89] <= { 8'b01111100 };
font_data[ 90] <= { 8'b01000010 };
font_data[ 91] <= { 8'b01111100 };
font_data[ 92] <= { 8'b01000010 };
font_data[ 93] <= { 8'b01000010 };
font_data[ 94] <= { 8'b01111100 };
font_data[ 95] <= { 8'b00000000 };

font_data[ 96] <= { 8'b00000000 };
font_data[ 97] <= { 8'b00011100 };
font_data[ 98] <= { 8'b00100010 };
font_data[ 99] <= { 8'b01000000 };
font_data[100] <= { 8'b01000000 };
font_data[101] <= { 8'b00100010 };
font_data[102] <= { 8'b00011100 };
font_data[103] <= { 8'b00000000 };

font_data[104] <= { 8'b00000000 };
font_data[105] <= { 8'b01111100 };
font_data[106] <= { 8'b01000010 };
font_data[107] <= { 8'b01000010 };
font_data[108] <= { 8'b01000010 };
font_data[109] <= { 8'b01000010 };
font_data[110] <= { 8'b01111100 };
font_data[111] <= { 8'b00000000 };

font_data[112] <= { 8'b00000000 };
font_data[113] <= { 8'b01111110 };
font_data[114] <= { 8'b01000000 };
font_data[115] <= { 8'b01111100 };
font_data[116] <= { 8'b01000000 };
font_data[117] <= { 8'b01000000 };
font_data[118] <= { 8'b01111110 };
font_data[119] <= { 8'b00000000 };

font_data[120] <= { 8'b00000000 };
font_data[121] <= { 8'b01111110 };
font_data[122] <= { 8'b01000000 };
font_data[123] <= { 8'b01111100 };
font_data[124] <= { 8'b01000000 };
font_data[125] <= { 8'b01000000 };
font_data[126] <= { 8'b01000000 };
font_data[127] <= { 8'b00000000 };
end

parameter N_NIBBLES = 16;
reg[3:0] data[N_NIBBLES-1:0];

// Latch display data
always @(posedge in_latch) begin
  data[0]  <= in_data0[7:4];
  data[1]  <= in_data0[3:0];
  data[2]  <= in_data1[7:4];
  data[3]  <= in_data1[3:0];
  data[4]  <= in_data2[7:4];
  data[5]  <= in_data2[3:0];
  data[6]  <= in_data3[7:4];
  data[7]  <= in_data3[3:0];
  data[8]  <= in_data4[7:4];
  data[9]  <= in_data4[3:0];
  data[10] <= in_data5[7:4];
  data[11] <= in_data5[3:0];
  data[12] <= in_data6[7:4];
  data[13] <= in_data6[3:0];
  data[14] <= in_data7[7:4];
  data[15] <= in_data7[3:0];
end

reg is_overlay;
wire is_pixel_active;
reg [7:0] scanline;
reg [2:0] scanline_x;

always @(posedge in_pix_clk) begin
  // Characters appear 8 pixels from top of screen (to not be cut off)
  // Also, avoid repeating the data in the X direction.
  scanline <= font_data[ { data[in_pix_x[6:3]], in_pix_y[2:0] } ];
  scanline_x <= ~in_pix_x[2:0];
  if (in_pix_y[9:4] == 0 && in_pix_y[3] == 1 && in_pix_x[9:7] == 0) begin
    is_overlay <= 1;
  end else begin
    is_overlay <= 0;
  end
end

assign is_pixel_active = scanline[scanline_x];

assign out_pixel_r = is_overlay ? (is_pixel_active ? 8'b1 : 8'b0)
                                : in_pixel_r;
assign out_pixel_g = is_overlay ? (is_pixel_active ? 8'b1 : 8'b0)
                                : in_pixel_g;
assign out_pixel_b = is_overlay ? (is_pixel_active ? 8'b1 : 8'b0)
                                : in_pixel_b;

endmodule
