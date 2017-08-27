module mod_grid_display(
  input       in_pix_clk,   // Clock to sync all pixel inputs/outputs to
  input [9:0] in_pix_x,     // Current pixel output position (x,y)
  input [9:0] in_pix_y,
  input       in_latch,
  input [7:0] in_pixel_r,   // Parent video pixel data to overlay on
  input [7:0] in_pixel_g,
  input [7:0] in_pixel_b,

  output [7:0] out_pixel_r, // Video pixel data after overlay
  output [7:0] out_pixel_g,
  output [7:0] out_pixel_b
);

reg is_overlay;
reg [7:0] pixel_r;
reg [7:0] pixel_g;
reg [7:0] pixel_b;

always @(posedge in_pix_clk) begin
  if (in_pix_y[3:0] == 4'b0000 || in_pix_y[3:0] == 4'b1111) begin
    is_overlay <= 1'b1;
  end else if (in_pix_x[3:0] == 4'b0000 || in_pix_x[3:0] == 4'b1111) begin
    is_overlay <= 1'b1;
  end else begin
    is_overlay <= 1'b0;
  end

  pixel_r <= 8'b00000000;
  pixel_g <= 8'b00000000;
  pixel_b <= 8'b11111111;
end

assign out_pixel_r = is_overlay ? pixel_r : in_pixel_r;
assign out_pixel_g = is_overlay ? pixel_g : in_pixel_g;
assign out_pixel_b = is_overlay ? pixel_b : in_pixel_b;

endmodule
