
// A very basic VGA encoder. Current position is given as an output
// and desired colors are piped in from outside. Also output are the
// necessary H-Sync and V-Sync signals.
module mod_vga_encoder(
  input clk_in_25_175_mhz,
  input vga_in_r,
  input vga_in_g,
  input vga_in_b,
  output vga_out_r,
  output vga_out_g,
  output vga_out_b,
  output vga_out_hsync,
  output vga_out_vsync,
  output [9:0] vga_out_current_x,
  output [9:0] vga_out_current_y
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

always @(posedge clk_in_25_175_mhz)
begin
  if (pix_x < hpixels - 1) begin
    pix_x <= pix_x + 1;
  end
  else
  begin
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
assign vga_out_hsync = (pix_x >= (res_x+hfp) && pix_x < (res_x+hfp+hpulse)) ? 0 : 1;
assign vga_out_vsync = (pix_y >= (res_y+vfp) && pix_y < (res_y+vfp+vpulse)) ? 0 : 1;

assign vga_out_current_x = pix_x;
assign vga_out_current_y = pix_y;

// Supress output in H-Blank and V-Blank
always @* begin
  if (pix_y < res_y && pix_x < res_x) begin
    vga_out_r <= vga_in_r;
    vga_out_g <= vga_in_g;
    vga_out_b <= vga_in_b;
  end else begin
    vga_out_r <= 0;
    vga_out_g <= 0;
    vga_out_b <= 0;
  end
end

endmodule
