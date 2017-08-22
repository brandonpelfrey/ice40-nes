
module top(
  input in_clk_12_mhz,
  output [7:0] out_leds,
  output out_vga_r,
  output out_vga_g,
  output out_vga_b,
  output out_vga_hsync,
  output out_vga_vsync
);

// Clock stuff
wire w_vga_clock;
mod_clock_master clock_master(
  .in_clk_12_mhz( in_clk_12_mhz ),
  .out_clk_25_175_mhz( w_vga_clock ),
);

// Hex digit output (TODO : Move this and VGA to a 'display' module)
wire w_hex_display_pixel_on;
mod_hex_display hex_display(
  .in_pix_x( w_vga_pix_x ),
  .in_pix_y( w_vga_pix_y ),
  .in_reset(),
  .out_pixel( w_hex_display_pixel_on ),
  .in_data0( counter[63:56] ),
  .in_data1( counter[55:48] ),
  .in_data2( counter[47:40] ),
  .in_data3( counter[39:32] ),
  .in_data4( counter[31:24] ),
  .in_data5( counter[23:16] ),
  .in_data6( counter[15:8] ),
  .in_data7( counter[7:0] )
);

// VGA Output
wire [9:0] w_vga_pix_x;
wire [9:0] w_vga_pix_y;
mod_vga_encoder vga_encoder(
  .in_clk_25_175_mhz( w_vga_clock ),
  .in_vga_r( w_hex_display_pixel_on ),
  .in_vga_g( w_hex_display_pixel_on ),
  .in_vga_b( w_hex_display_pixel_on ),
  .out_vga_r( out_vga_r ),
  .out_vga_g( out_vga_g ),
  .out_vga_b( out_vga_b ),
  .out_vga_hsync( out_vga_hsync ),
  .out_vga_vsync( out_vga_vsync ),
  .out_vga_current_x( w_vga_pix_x ),
  .out_vga_current_y( w_vga_pix_y )
);

// Some internal state, used to update an on-screen counter
reg [63:0] counter;
assign out_leds[7:0] = counter[28:21]; // blinky blinky

always @ (posedge in_clk_12_mhz) begin
  counter <= counter + 1;
end
endmodule
