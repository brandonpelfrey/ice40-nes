// This module displays hex values provided on several 8bit
// data ports. They appear as hex values at the top left of
// the output image.
module mod_hex_display(
  input [9:0] in_pix_x, // Current pixel output position (x,y)
  input [9:0] in_pix_y,
  input in_reset,
  input [7:0] in_data0, // Input data lines. These are written
  input [7:0] in_data1, // to internal registers.
  input [7:0] in_data2, // TODO : Implement latching.
  input [7:0] in_data3,
  input [7:0] in_data4,
  input [7:0] in_data5,
  input [7:0] in_data6,
  input [7:0] in_data7,
  output out_pixel     // Single high/low to be drawn for the current pixel
);

// 8x8 font data for hex digits 0-F
reg [63:0] font_data[15:0];
initial begin
font_data[0]  <= 64'h3E63737B6F673E00;
font_data[1]  <= 64'h0C0E0C0C0C0C3F00;
font_data[2]  <= 64'h1E33301C06333F00;
font_data[3]  <= 64'h1E33301C30331E00;
font_data[4]  <= 64'H383C36337F307800;
font_data[5]  <= 64'h3F031F3030331E00;
font_data[6]  <= 64'h1C06031F33331E00;
font_data[7]  <= 64'h3F3330180C0C0C00;
font_data[8]  <= 64'h1E33331E33331E00;
font_data[9]  <= 64'h1E33333E30180E00;
font_data[10] <= 64'h0C1E33333F333300;
font_data[11] <= 64'h3F66663E66663F00;
font_data[12] <= 64'h3C66030303663C00;
font_data[13] <= 64'h1F36666666361F00;
font_data[14] <= 64'h7F46161E16467F00;
font_data[15] <= 64'h7F46161E16060F00;
end

parameter N_NIBBLES = 16;
reg[3:0] data[N_NIBBLES-1:0];

reg pix_reg;
always @* begin
  // TODO : Reset-data logic

  // TODO : This is delayed by one pixel clock cycle..

  // Characters appear at the top of the screen (only top 8 pixels)
  // Also, avoid repeating the data in the X direction.
  if(in_pix_y[9:3] == 0 && in_pix_x[9:7] == 0) begin

    // Get the nibble at this block in the x-direction, then get the
    // appropriate font data. Need to Not the y to invert. TODO : Y-Flip the
    // font data and remove the Not.
    pix_reg <= font_data[ data[ in_pix_x[6:3] ] ]
                        [ {~in_pix_y[2:0], in_pix_x[2:0]} ];
  end else begin
    pix_reg <= 0;
  end

  // clock in data to be shown.
  // We should either latch this for a longer period, or just 
  // directly wire this to out_pixel
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

assign out_pixel = pix_reg;

endmodule
