module mod_clock_master(
  input in_clk_12_mhz,
  output out_clk_25_175_mhz
);

// VGA has a pixel clock which defines the time between 
// each consecutive pixel. For a given video mode, which is
// 640 x 480 @ 60 fps here, you need a specific pixel clock
// speed. In this case, 25.175 MHz. 'icepll -o 25.175' will
// determine the best coefficients in the PLL equation to
// get as close to this as possible (monitor is pretty
// tolerant to be slightly off).
SB_PLL40_CORE #(
  .FEEDBACK_PATH("SIMPLE"),
  .PLLOUT_SELECT("GENCLK"),
  .DIVF(7'b1000010),
  .DIVQ(3'b101),
  .DIVR(4'b0000),
  .FILTER_RANGE(3'b001)
) uut (
  .REFERENCECLK(in_clk_12_mhz),
  .PLLOUTCORE(out_clk_25_175_mhz),
  .RESETB(1'b1),
  .BYPASS(1'b0)
);

// TODO : Any other clocks needed elsewhere in the system..
// (PPU Clock, APU Clock, CPU Clock, RS-232)

endmodule
