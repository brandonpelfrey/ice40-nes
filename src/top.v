module top(
  input in_clk_12_mhz,
  output [7:0] out_leds,

  // VGA666
  output out_vga_r,
  output out_vga_g,
  output out_vga_b,
  output out_vga_hsync,
  output out_vga_vsync,

  // Controller 0
  output out_controller0_pulse,
  output out_controller0_latch,
  input in_controller0_data
);

// Clock stuff
wire w_vga_clock;
wire w_sdram_clock;
mod_clock_master clock_master(
  .in_clk_12_mhz( in_clk_12_mhz ),
  .out_clk_25_175_mhz( w_vga_clock ),
  .out_clk_166_mhz( w_sdram_clock ),
);

// VGA Display Interface
wire [9:0] w_vga_pix_x;
wire [9:0] w_vga_pix_y;

// Wire from grid -> next overlay
wire [7:0] w_grid_r;
wire [7:0] w_grid_g;
wire [7:0] w_grid_b;

// Grid Overlay
mod_grid_display grid_display(
  .in_pix_clk( w_vga_clock ),
  .in_pix_x( w_vga_pix_x ),
  .in_pix_y( w_vga_pix_y ),
  .in_pixel_r( 8'b11111111 ),
  .in_pixel_g( 8'b00000000 ),
  .in_pixel_b( 8'b00000000 ),
  .out_pixel_r( w_grid_r ),
  .out_pixel_g( w_grid_g ),
  .out_pixel_b( w_grid_b )
);

// Wire from hex output -> next overlay
wire [7:0] w_hex_r;
wire [7:0] w_hex_g;
wire [7:0] w_hex_b;

// Hex Digit Overlay
wire w_hex_display_pixel_on;
mod_hex_display hex_display(
  .in_pix_clk( w_vga_clock ),
  .in_pix_x( w_vga_pix_x ),
  .in_pix_y( w_vga_pix_y ),
  .in_latch( out_vga_vsync ),
  .in_data0( counter[63:56] ),
  .in_data1( counter[55:48] ),
  .in_data2( counter[47:40] ),
  .in_data3( counter[39:32] ),
  .in_data4( counter[31:24] ),
  .in_data5( counter[23:16] ),
  .in_data6( counter[15:8] ),
  .in_data7( controller0_buttons[7:0] ),
  .in_pixel_r( w_grid_r ),
  .in_pixel_g( w_grid_g ),
  .in_pixel_b( w_grid_b ),
  .out_pixel_r( w_hex_r ),
  .out_pixel_g( w_hex_g ),
  .out_pixel_b( w_hex_b )
);

// VGA Output
// Input pixel values are latched on pixel clock edge
// Pixel coordinate outputs indicate position of next clock cycle, not current
// cycle
mod_vga_encoder vga_encoder(
  .in_clk_25_175_mhz( w_vga_clock ),
  .in_vga_r( w_hex_r ),
  .in_vga_g( w_hex_g ),
  .in_vga_b( w_hex_b ),
  .out_vga_r( { out_vga_r } ),
  .out_vga_g( { out_vga_g } ),
  .out_vga_b( { out_vga_b } ),
  .out_vga_hsync( out_vga_hsync ),
  .out_vga_vsync( out_vga_vsync ),
  .out_vga_next_x( w_vga_pix_x ),
  .out_vga_next_y( w_vga_pix_y )
);

wire [7:0] controller0_buttons;
mod_controller controller0(
  .in_clk_controller( counter[8] ),
  .in_vsync( out_vga_vsync ),
  .in_controller_data( in_controller0_data ),
  .out_controller_latch( out_controller0_latch ),
  .out_controller_pulse( out_controller0_pulse ),
  .out_controller_buttons( controller0_buttons )
);

// Some internal state, used to update an on-screen counter
reg [63:0] counter;
always @(posedge in_clk_12_mhz) begin
  counter <= counter + 1;
end

// Hardware Output
assign out_leds[7:0] = controller0_buttons[7:0];

endmodule
