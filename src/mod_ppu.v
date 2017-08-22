// Encapsulates the inner function of the PPU, along with rendering
module mod_ppu(
  input in_ppu_pixel_clk,
  output out_red,
  output out_green,
  output out_blue,
);

// Externally-accessible PPU Registers (http://wiki.nesdev.com/w/index.php/PPU_registers)
reg [7:0] PPUCTRL;
reg [7:0] PPUMASK;
reg [7:0] PPUSTATUS;
reg [7:0] OAMADDR;
reg [7:0] OAMDATA;
reg [7:0] PPUSCROLL;
reg [7:0] PPUADDR;
reg [7:0] PPUDATA;
reg [7:0] OAMDMA;


// Internal PPU Registers (http://wiki.nesdev.com/w/index.php/PPU_scrolling)
reg [14:0] vram_address;       // 'v'
reg [14:0] vram_address_temp;  // 't'
reg [2:0]  fine_x_scroll;      // 'x'
reg        first_write_toggle; // 'w'

/*
The 15 bit registers t and v are composed this way during rendering:

yyy NN YYYYY XXXXX
||| || ||||| +++++-- coarse X scroll
||| || +++++-------- coarse Y scroll
||| ++-------------- nametable select
+++----------------- fine Y scroll
*/

always @(posedge in_ppu_pixel_clk) begin
  // TODO : Rendering..
end

endmodule
