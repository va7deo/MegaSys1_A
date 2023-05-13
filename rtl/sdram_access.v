/*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY;without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
module sdram_access (
    input reset,
    input clk,
    input reset_sdram,

    input  [7:0]  ioctl_index,
    input  [25:0] ioctl_addr,
    input  [7:0]  ioctl_dout,
    output [7:0]  ioctl_din,
    input         ioctl_wr,
    
    input         downloading,
    input         prog_rdy,
    output [21:0] prog_addr,
    output [15:0] prog_data,
    output [1:0]  prog_mask,    // byte mask
    output [1:0]  prog_ba,      // bank #
    output reg    prog_we,      // write
    output        prog_rd,      // read ??

    // bank 
    output [21:0] ba0_addr,
    output [21:0] ba1_addr,
    output [21:0] ba2_addr,
    output [21:0] ba3_addr,
    output [ 3:0] ba_rd,
    output        ba_wr,
    output [15:0] ba0_din,
    output [ 1:0] ba0_din_m,  // write mask
    input  [ 3:0] ba_ack,
    input  [ 3:0] ba_dst,
    input  [ 3:0] ba_dok,
    input  [ 3:0] ba_rdy,
    input  [15:0] data_read,

    // main cpu
    input         main_cpu_cs,
    output        main_cpu_ready,
    input  [18:0] main_cpu_addr,
    output [15:0] main_cpu_data,
    
    // sound cpu
    input         sound_cpu_cs,
    output        sound_cpu_ready,
    input  [16:0] sound_cpu_addr,
    output  [7:0] sound_cpu_data,
    
    // scroll0
    input         scroll0_cs,
    output        scroll0_ready,
    input  [21:0] scroll0_addr,
    output [63:0] scroll0_data,

    // scroll1
    input         scroll1_cs,
    output        scroll1_ready,
    input  [21:0] scroll1_addr,
    output [63:0] scroll1_data,

    // scroll2
    input         scroll2_cs,
    output        scroll2_ready,
    input  [21:0] scroll2_addr,
    output [63:0] scroll2_data,

    // sprites
    input         sprite_cs,
    output        sprite_ready,
    input  [21:0] sprite_addr,
    output [63:0] sprite_data,
    
    // pcm 1
    input         pcm1_cs,
    output        pcm1_ready,
    input  [19:0] pcm1_addr,
    output [7:0]  pcm1_data,

    // pcm 2
    input         pcm2_cs,
    output        pcm2_ready,
    input  [19:0] pcm2_addr,
    output [7:0]  pcm2_data
);

localparam main_cpu_len  = 26'h40000;
localparam sound_cpu_len = 26'h20000;
localparam scroll0_len   = 26'h60000;
localparam scroll1_len   = 26'h40000;
localparam scroll2_len   = 26'h20000;
localparam sprite_len    = 26'h60000;
localparam pcm1_len      = 26'h40000;
localparam pcm2_len      = 26'h40000;

// bank 0
localparam main_cpu_base       = 26'h0;
localparam sound_cpu_base      = main_cpu_base + main_cpu_len;
localparam pcm1_base           = sound_cpu_base + sound_cpu_len;
localparam pcm2_base           = pcm1_base + pcm1_len;

// bank 1
localparam scroll0_base        = pcm2_base + pcm2_len;
localparam scroll1_base        = scroll0_base + scroll0_len;
localparam scroll2_base        = scroll1_base + scroll1_len;
localparam sprite_base         = scroll2_base + scroll2_len;

wire dl_main_cpu    = ioctl_addr >= main_cpu_base   && ioctl_addr < sound_cpu_base;
wire dl_sound_cpu   = ioctl_addr >= sound_cpu_base  && ioctl_addr < pcm1_base;
wire dl_pcm1        = ioctl_addr >= pcm1_base       && ioctl_addr < pcm2_base;
wire dl_pcm2        = ioctl_addr >= pcm2_base       && ioctl_addr < scroll0_base;

wire dl_scroll0     = ioctl_addr >= scroll0_base    && ioctl_addr < scroll1_base;
wire dl_scroll1     = ioctl_addr >= scroll1_base    && ioctl_addr < scroll2_base;
wire dl_scroll2     = ioctl_addr >= scroll2_base    && ioctl_addr < sprite_base;
wire dl_sprite      = ioctl_addr >= sprite_base     && ioctl_addr < ( sprite_base  + sprite_len );

reg [7:0]  pre_data;
reg [1:0]  pre_mask;
reg [21:0] pre_addr;
reg [1:0]  pre_ba;

assign prog_rd   = 0;
assign prog_data = {2{pre_data}};
assign prog_mask = pre_mask;
assign prog_addr = pre_addr;
assign prog_ba   = pre_ba;

wire [21:0] main_cpu_ofs   = ioctl_addr;
wire [21:0] sound_cpu_ofs  = ioctl_addr - sound_cpu_base;
wire [21:0] pcm1_ofs       = ioctl_addr - pcm1_base;
wire [21:0] pcm2_ofs       = ioctl_addr - pcm2_base;

wire [21:0] scroll0_ofs    = ioctl_addr - scroll0_base;
wire [21:0] scroll1_ofs    = ioctl_addr - scroll1_base;
wire [21:0] scroll2_ofs    = ioctl_addr - scroll2_base;
wire [21:0] sprite_ofs     = ioctl_addr - sprite_base;

// main loader for ROM data
always @(posedge clk) begin
    if ( ioctl_wr && ioctl_index == 0 ) begin
        prog_we  <= 1'b1;
//        pre_data <= ioctl_dout;
        pre_data <= ioctl_addr;
        pre_mask <= {~ioctl_addr[0],ioctl_addr[0]};
        
        pre_addr <= ioctl_addr >> 1;
        // convert byte address to word address
//        pre_addr <= dl_main_cpu  ? main_cpu_ofs  >> 1 :
//                    dl_sound_cpu ? sound_cpu_ofs >> 1 :
//                    dl_pcm1      ? pcm1_ofs      >> 1 :
//                    dl_pcm2      ? pcm2_ofs      >> 1 :
//                    dl_scroll0   ? scroll0_ofs   >> 1 :
//                    dl_scroll1   ? scroll1_ofs   >> 1 :
//                    dl_scroll2   ? scroll2_ofs   >> 1 :
//                    dl_sprite    ? sprite_ofs    >> 1 :
//                    { 22 { 1'b1 }};
                    
        // select bank ( gfx bank = 1 ) 
        pre_ba <=  dl_scroll0 | dl_scroll1 | dl_scroll2 | dl_sprite;
    end else begin
        // prog_rdy asserted when sdram write done?
        if (!downloading || prog_rdy) prog_we <= 1'b0;
    end
end

assign ba_wr = 1'b0;

jtframe_rom_4slots 
#(
    .SDRAMW(22),

    // m68k main
    .SLOT0_OFFSET(main_cpu_base),  // 0
    .SLOT0_AW    (19),  // 0x20000 x 2
    .SLOT0_DW    (16),
    .SLOT0_LATCH (1),
    .SLOT0_DOUBLE(1),

    // m68k sound
    .SLOT1_OFFSET(sound_cpu_base),
    .SLOT1_AW    (20),
    .SLOT1_DW    (16),  // 0x10000 x 2
    .SLOT1_LATCH (1),
    .SLOT1_DOUBLE(1),

    // M6295 
    .SLOT2_OFFSET(pcm1_base),
    .SLOT2_AW    (18),  // 0x40000 x 1
    .SLOT2_DW    (8),
    .SLOT2_LATCH (1),
    .SLOT2_DOUBLE(1),

    // M6295
    .SLOT3_OFFSET(pcm2_base),
    .SLOT3_AW    (18),  // 0x40000 x 1
    .SLOT3_DW    (8),
    .SLOT3_LATCH (1),
    .SLOT3_DOUBLE(1)
) bank_0
(
    .rst         (reset),
    .clk         (clk),

    .slot0_cs    (main_cpu_cs),
    .slot0_ok    (main_cpu_ready),
    .slot0_addr  (main_cpu_addr),
    .slot0_dout  (main_cpu_data),

    .slot1_cs    (sound_cpu_cs),
    .slot1_ok    (sound_cpu_ready),
    .slot1_addr  (sound_cpu_addr),
    .slot1_dout  (sound_cpu_data),

    .slot2_cs    (pcm1_cs),
    .slot2_ok    (pcm1_ready),
    .slot2_addr  (pcm1_addr),
    .slot2_dout  (pcm1_data),

    .slot3_cs    (pcm2_cs),
    .slot3_ok    (pcm2_ready),
    .slot3_addr  (pcm2_addr),
    .slot3_dout  (pcm2_data),

    .sdram_addr  (ba0_addr),
    .sdram_req   (ba_rd[0]),
    .sdram_ack   (ba_ack[0]),
    .data_dst    (ba_dst[0]),
    .data_rdy    (ba_rdy[0]),
    .data_read   (data_read)
);

// all gfx access is 64 bit
jtframe_rom_4slots 
#(
    .SDRAMW      (22),

    .SLOT0_OFFSET(scroll0_base),  // 0
    .SLOT0_AW    (17),  // 0x20000 x 4
    .SLOT0_DW    (64),
    .SLOT0_DOUBLE(1),
    .SLOT0_LATCH (0),

    .SLOT1_OFFSET(scroll1_base),
    .SLOT1_AW    (17),  // 0x20000 x 4
    .SLOT1_DW    (64),
    .SLOT1_DOUBLE(1),
    .SLOT1_LATCH (0),

    .SLOT2_OFFSET(scroll2_base),
    .SLOT2_AW    (17),  // 0x20000 x 4
    .SLOT2_DW    (64),
    .SLOT2_DOUBLE(1),
    .SLOT2_LATCH (0),

    .SLOT3_OFFSET(sprite_base),
    .SLOT3_AW    (17),  // 0x20000 x 4
    .SLOT3_DW    (64),
    .SLOT3_DOUBLE(1),
    .SLOT3_LATCH (0)
) bank_1
(
    .rst         (reset),
    .clk         (clk),

    .slot0_cs    (scroll0_cs),
    .slot0_ok    (scroll0_ready),
    .slot0_addr  (scroll0_addr),
    .slot0_dout  (scroll0_data),

    .slot1_cs    (scroll1_cs),
    .slot1_ok    (scroll1_ready),
    .slot1_addr  (scroll1_addr),
    .slot1_dout  (scroll1_data),

    .slot2_cs    (scroll2_cs),
    .slot2_ok    (scroll2_ready),
    .slot2_addr  (scroll2_addr),
    .slot2_dout  (scroll2_data),

    .slot3_cs    (sprite_cs),
    .slot3_ok    (sprite_ready),
    .slot3_addr  (sprite_addr),
    .slot3_dout  (sprite_data),

    .sdram_addr  (ba1_addr),
    .sdram_req   (ba_rd[1]),
    .sdram_ack   (ba_ack[1]),
    .data_dst    (ba_dst[1]),
    .data_rdy    (ba_rdy[1]),
    .data_read   (data_read)
);

endmodule
