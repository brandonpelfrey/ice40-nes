
module top(
  input clk_in_12_mhz,
  output [7:0] leds,
  output vga_r,
  output vga_g,
  output vga_b,
  output vga_hsync,
  output vga_vsync
);

// Clock stuff
wire vga_clock;
mod_clock_master clock_master(
  .clk_in_12_mhz( clk_in_12_mhz ),
  .clk_out_25_175_mhz( vga_clock ),
);

// Hex digit output (TODO : Move this and VGA to a 'display' module)
wire hex_display_pixel_on;
mod_hex_display hex_display(
  .pix_x( vga_pix_x ),
  .pix_y( vga_pix_y ),
  .reset(),
  .pix_out( hex_display_pixel_on ),
  .data0( counter[63:56] ),
  .data1( counter[55:48] ),
  .data2( counter[47:40] ),
  .data3( counter[39:32] ),
  .data4( counter[31:24] ),
  .data5( counter[23:16] ),
  .data6( counter[15:8] ),
  .data7( counter[7:0] )
);

// VGA Output
wire [9:0] vga_pix_x;
wire [9:0] vga_pix_y;
mod_vga_encoder vga_encoder(
  .clk_in_25_175_mhz( vga_clock ),
  .vga_in_r( hex_display_pixel_on ),
  .vga_in_g( hex_display_pixel_on ),
  .vga_in_b( hex_display_pixel_on ),
  .vga_out_r( vga_r ),
  .vga_out_g( vga_g ),
  .vga_out_b( vga_b ),
  .vga_out_hsync( vga_hsync ),
  .vga_out_vsync( vga_vsync ),
  .vga_out_current_x( vga_pix_x ),
  .vga_out_current_y( vga_pix_y )
);

// Some internal state, used to update an on-screen counter
reg [63:0] counter;
assign leds[7:0] = counter[28:21]; // blinky blinky

always @ (posedge clk_in_12_mhz) begin
  counter <= counter + 1;
end
endmodule
