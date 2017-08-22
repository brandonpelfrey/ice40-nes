// This module displays hex values provided on several 8bit
// data ports. They appear as hex values at the top left of
// the output image.
module mod_hex_display(
  input [9:0] pix_x, // Current pixel output position (x,y)
  input [9:0] pix_y,
  input reset,
  input [7:0] data0, // Input data lines. These are written
  input [7:0] data1, // to internal registers.
  input [7:0] data2, // TODO : Implement latching.
  input [7:0] data3,
  input [7:0] data4,
  input [7:0] data5,
  input [7:0] data6,
  input [7:0] data7,
  output pix_out     // Single high/low to be drawn for the current pixel
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
  if(pix_y[9:3] == 0 && pix_x[9:7] == 0) begin

    // Get the nibble at this block in the x-direction, then get the
    // appropriate font data. Need to Not the y to invert. TODO : Y-Flip the
    // font data and remove the Not.
    pix_reg <= font_data[ data[ pix_x[6:3] ] ]
                        [ {~pix_y[2:0], pix_x[2:0]} ];
  end else begin
    pix_reg <= 0;
  end

  // clock in data to be shown.
  // We should either latch this for a longer period, or just 
  // directly wire this to pix_out
  data[0]  <= data0[7:4];
  data[1]  <= data0[3:0];
  data[2]  <= data1[7:4];
  data[3]  <= data1[3:0];
  data[4]  <= data2[7:4];
  data[5]  <= data2[3:0];
  data[6]  <= data3[7:4];
  data[7]  <= data3[3:0];
  data[8]  <= data4[7:4];
  data[9]  <= data4[3:0];
  data[10] <= data5[7:4];
  data[11] <= data5[3:0];
  data[12] <= data6[7:4];
  data[13] <= data6[3:0];
  data[14] <= data7[7:4];
  data[15] <= data7[3:0];
end

assign pix_out = pix_reg;

endmodule
