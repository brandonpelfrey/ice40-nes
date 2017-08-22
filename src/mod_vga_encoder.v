
// A very basic VGA encoder. Current position is given as an output
// and desired colors are piped in from outside. Also output are the
// necessary H-Sync and V-Sync signals.
module mod_vga_encoder(
  input in_clk_25_175_mhz,
  input in_vga_r,
  input in_vga_g,
  input in_vga_b,
  output out_vga_r,
  output out_vga_g,
  output out_vga_b,
  output out_vga_hsync,
  output out_vga_vsync,
  output [9:0] out_vga_current_x,
  output [9:0] out_vga_current_y
);

// Current position in the raster
reg [9:0] pix_x;
reg [9:0] pix_y;

// Some other constants for the VGA signal. Each line begins
// with actual image data, then an H-Sync front porch, pulse,
// and back porch, which are used for locking onto a signal at
// the monitor. A similar thing happens after the last line
// of color data: There are several lines forming a V-Sync
// front porch, pulse, and back porch.
parameter res_x = 640;
parameter res_y = 480;

parameter hfp    = 16;   // horizontal front porch
parameter hpulse = 96;   // hsync pulse length
parameter hbp    = 48;   // horizontal back porch

parameter vfp    = 10;   // vertical front porch
parameter vpulse = 2;    // vsync pulse length
parameter vbp    = 33;   // vertical back porch

// horizontal/vertical pixels per line including non-visible
parameter hpixels = res_x + hfp + hpulse + hbp;
parameter vlines  = res_y + vfp + vpulse + vbp;

always @(posedge in_clk_25_175_mhz) begin
  if (pix_x < hpixels - 1) begin
    pix_x <= pix_x + 1;
  end else begin
    // Next line
    pix_x <= 0;

    if (pix_y < vlines - 1) begin
      pix_y <= pix_y + 1;
    end else begin
      // Next frame
      pix_y <= 0;
    end
  end
end

// In this video mode, hsync and vsync are active low when the pulse
// is supposed to take place
assign out_vga_hsync = (pix_x >= (res_x+hfp) && pix_x < (res_x+hfp+hpulse)) ? 0 : 1;
assign out_vga_vsync = (pix_y >= (res_y+vfp) && pix_y < (res_y+vfp+vpulse)) ? 0 : 1;

assign out_vga_current_x = pix_x;
assign out_vga_current_y = pix_y;

// Supress output in H-Blank and V-Blank
always @* begin
  if (pix_y < res_y && pix_x < res_x) begin
    out_vga_r <= in_vga_r;
    out_vga_g <= in_vga_g;
    out_vga_b <= in_vga_b;
  end else begin
    out_vga_r <= 0;
    out_vga_g <= 0;
    out_vga_b <= 0;
  end
end

endmodule
