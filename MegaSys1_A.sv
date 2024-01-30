//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

`default_nettype none

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output        CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,      // = ~(VBlank | HBlank)
    output        VGA_F1,
    output [2:0]  VGA_SL,
    output        VGA_SCALER,  // Force VGA scaler
    output        VGA_DISABLE, // Analog out is off

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef MISTER_FB
    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output  [4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output  [7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output  [1:0] BUTTONS,

    //Audio
    input         CLK_AUDIO, // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout   [3:0] ADC_BUS,

    //SD-SPI
    output        SD_SCK,
    output        SD_MOSI,
    input         SD_MISO,
    output        SD_CS,
    input         SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output  [1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input         UART_CTS,
    output        UART_RTS,
    input         UART_RXD,
    output        UART_TXD,
    output        UART_DTR,
    input         UART_DSR,

`ifdef MISTER_ENABLE_YC
    output [39:0] CHROMA_PHASE_INC,
    output        YC_EN,
    output        PALFLAG,
`endif

    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT,

    input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_MIX = 0;
assign LED_USER =  |{ m68kp_a[0], m68ks_a[0], max_count, scroll0_x, scroll0_y, oki0_sample_clk, oki1_sample_clk};
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//reg    [7:0] max_count;
//reg   [31:0] req_count;
//reg   [31:0] wait_count;
//reg   [31:0] max_wait;
//reg          prev_cs;

// Status Bit Map:
//              Upper Case                     Lower Case           
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X  XXXXXXXXXXX     X X XXXXXXXXX XXXXXXXXXXXXXXXXXX      XXXXXXXX

wire [1:0] aspect_ratio = status[9:8];
wire       orientation  = ~status[3];
wire [2:0] scan_lines   = status[6:4];
reg        refresh_mod;
reg        new_vmode;

always @(posedge clk_sys) begin
    if (refresh_mod != status[19]) begin
        refresh_mod <= status[19];
        new_vmode <= ~new_vmode;
    end
end

wire [3:0] hs_offset = status[27:24];
wire [3:0] vs_offset = status[31:28];
wire [3:0] hs_width  = status[59:56];
wire [3:0] vs_width  = status[63:60];

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd8 : 8'd7) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd7 : 8'd8) : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
    "MegaSys1_A;;",
    "-;",
    "P1,Video Settings;",
    "P1-;",
    "P1O89,Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
    "P1O3,Orientation,Horz,Vert;",
    "P1-;",
    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%,CRT 100%;",
    "P1OA,Force Scandoubler,Off,On;",
    "P1-;",
    "P1O7,Video Mode,NTSC,PAL;",
    "P1OM,Video Signal,RGBS/YPbPr,Y/C;",
    "P1OJ,Refresh Rate,Native,NTSC;",
    "P1-;",
    "P1OOR,H-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1OSV,V-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P1oOR,H-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1oSV,V-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P2,Audio Settings;",
    "P2-;",
    "P2OC,Audio Mix,Mono,Stereo;",
    "P2-;",
    //"P2OB,OPM/ADPCM Audio,On,Off;",
    //"P2-;",
    "P2oBC,ADPCM-0 Volume,Default,50%,75%,Off;",
    "P2oDE,ADPCM-1 Volume,Default,50%,75%,Off;",
    "P2oFG,OPM Volume,Default,50%,25%,Off;",
    "P2-;",
    "-;",
    "P3,Core Options;",
    "P3-;",
    "P3oH,Swap P1/P2 Joystick,Off,On;",
    "P3-;",
    "P3OF,68k Freq.,6Mhz,7.2MHz;",
    "P3-;",
    "P3-;",
    "P3-;",
    "P3o0,P1 Reserve 1,Off,On;",
    "P3o1,P1 Reserve 2,On,Off;",
    "P3o2,P1 Reserve 3,Off,On;",
    "P3o3,P1 Reserve 4,Off,On;",
    "P3-;",
    "P3o4,P2 Reserve 1,On,Off;",
    "P3o5,P2 Reserve 2,On,Off;",
    "P3o6,P2 Reserve 3,Off,On;",
    "P3o7,P2 Reserve 4,On,Off;",
    "P3-;",
    "P3o8,Unknown,Off,On;",
    "P3o9,Unknown,Off,On;",
    "P3oA,Unknown,Off,On;",
    "P3-;",
    "DIP;",
    "-;",
    "OK,Pause OSD,Off,When Open;",
    "OL,Dim Video,Off,10s;",
    "-;",
    "R0,Reset;",
    "V,v",`BUILD_DATE
};

wire hps_forced_scandoubler;
wire forced_scandoubler = hps_forced_scandoubler | status[10];

wire  [1:0] buttons;
wire [63:0] status;
wire [10:0] ps2_key;
wire [15:0] joy0, joy1;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .buttons(buttons),
    .ps2_key(ps2_key),
    .status(status),
    .status_menumask(direct_video),
    .forced_scandoubler(hps_forced_scandoubler),
    .gamma_bus(gamma_bus),
    .new_vmode(new_vmode),
    .direct_video(direct_video),
    .video_rotated(video_rotated),

    .ioctl_download(ioctl_download),
    .ioctl_upload(ioctl_upload),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_din(ioctl_din),
    .ioctl_index(ioctl_index),
    .ioctl_wait(ioctl_wait),

    .joystick_0(joy0),
    .joystick_1(joy1)
);

// INPUT

// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end


localparam P47       = 0;
localparam PHANTASM  = 2;
localparam RODLAND   = 3;
localparam RODLANDJ  = 4;
localparam SHINGEN   = 5;
localparam ASTYANAX  = 6;
localparam SOLDAM    = 7;
localparam SOLDAMJ   = 8;
localparam EDFP      = 9;
localparam INYOURF   = 10;
localparam STDRAGON  = 11;
localparam STDRAGONA = 12;
localparam HACHOO    = 13;
localparam PLUSALPH  = 14;
localparam IGANINJU  = 15;
localparam JITSUPRO  = 16;

reg [23:0] prom [0:15];

reg [7:0]  irq1_scanline;

always @(posedge clk_sys) begin
    if (ioctl_wr && ioctl_index==1) begin
        pcb <= ioctl_dout;
    end

    // priority table
    if (ioctl_wr && ioctl_index==2) begin
        if ( ioctl_addr[1:0] > 0 ) begin
            prom[ioctl_addr[5:2]][ { ~ioctl_addr[1:0], 3'b111 } -: 8] <= ioctl_dout;
        end
    end

    if (ioctl_wr && ioctl_index==3) begin
        irq1_scanline <= ioctl_dout;
    end
end

wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [26:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

reg   [4:0] pcb;
reg   [7:0] cfg;

wire [21:0] gamma_bus;

//<buttons names="Fire,Jump,Start,Coin,Pause" default="A,B,R,L,Start" />
reg [15:0] p1;
reg [15:0] p2;
reg [15:0] dsw;
reg [15:0] system;

always @ (posedge clk_sys ) begin
    p1   <=  ~{ 8'h00, p1_buttons[3:0], p1_up, p1_down, p1_left, p1_right };
    p2   <=  ~{ reserve_2p_4, reserve_2p_3, reserve_2p_2, reserve_2p_1, reserve_1p_4, reserve_1p_3, reserve_1p_2, reserve_1p_1, p2_buttons[3:0], p2_up, p2_down, p2_left, p2_right };
    dsw <= { sw[0], sw[1] };
    system <= ~{ 8'h00, coin_b, coin_a, service, unknown_2, unknown_1, unknown_0, start2, start1 };
end

reg        p1_swap;

reg        p1_right;
reg        p1_left;
reg        p1_down;
reg        p1_up;
reg [3:0]  p1_buttons;

reg        p2_right;
reg        p2_left;
reg        p2_down;
reg        p2_up;
reg [3:0]  p2_buttons;

reg start1;
reg start2;
reg coin_a;
reg coin_b;
reg b_pause;
reg service;

// Purpose unknown, set like PCB
reg        reserve_1p_1;
reg        reserve_1p_2;
reg        reserve_1p_3;
reg        reserve_1p_4;

reg        reserve_2p_1;
reg        reserve_2p_2;
reg        reserve_2p_3;
reg        reserve_2p_4;

// Purpose unknown, unknown_1 registers as coinup on PCB
reg        unknown_0;
reg        unknown_1;
reg        unknown_2;

always @ (posedge clk_sys) begin
    p1_swap <= status[49];

    if ( status[49] == 0 ) begin
        p1_right   <= joy0[0]   | key_p1_right;
        p1_left    <= joy0[1]   | key_p1_left;
        p1_down    <= joy0[2]   | key_p1_down;
        p1_up      <= joy0[3]   | key_p1_up;
        p1_buttons <= joy0[7:4] | { key_p1_d, key_p1_c, key_p1_b, key_p1_a };

        start1     <= joy0[8]   | joy1[8]  | key_start_1p;
        coin_a     <= joy0[10]  | joy1[10] | key_coin_a;

        p2_right   <= joy1[0]   | key_p2_right;
        p2_left    <= joy1[1]   | key_p2_left;
        p2_down    <= joy1[2]   | key_p2_down;
        p2_up      <= joy1[3]   | key_p2_up;
        p2_buttons <= joy1[7:4] | { key_p2_d, key_p2_c, key_p2_b, key_p2_a };

        start2     <= joy0[9]   | joy1[9]  | key_start_2p;
        coin_b     <= joy0[11]  | joy1[11] | key_coin_b;
    end else begin
        p2_right   <= joy0[0]   | key_p1_right;
        p2_left    <= joy0[1]   | key_p1_left;
        p2_down    <= joy0[2]   | key_p1_down;
        p2_up      <= joy0[3]   | key_p1_up;
        p2_buttons <= joy0[7:4] | { key_p1_d, key_p1_c, key_p1_b, key_p1_a };

        start2     <= joy0[8]   | joy1[8]  | key_start_1p;
        coin_b     <= joy0[10]  | joy1[10] | key_coin_a;

        p1_right   <= joy1[0]   | key_p2_right;
        p1_left    <= joy1[1]   | key_p2_left;
        p1_down    <= joy1[2]   | key_p2_down;
        p1_up      <= joy1[3]   | key_p2_up;
        p1_buttons <= joy1[7:4] | { key_p2_d, key_p2_c, key_p2_b, key_p2_a };

        start1     <= joy1[9]   | joy0[9]  | key_start_2p;
        coin_a     <= joy0[11]  | joy1[11] | key_coin_b;
    end
end

always @ (posedge clk_sys) begin
    service   <= key_service;

    b_pause   <= joy0[12] | joy1[12] | key_pause;

    reserve_1p_1 <= status[32];
    reserve_1p_2 <= ~status[33];
    reserve_1p_3 <= status[34];
    reserve_1p_4 <= status[35];

    reserve_2p_1 <= ~status[36];
    reserve_2p_2 <= ~status[37];
    reserve_2p_3 <= status[38];
    reserve_2p_4 <= ~status[39];

    unknown_0 <= status[40];
    unknown_1 <= status[41];
    unknown_2 <= status[42];
end

// Keyboard handler

reg key_start_1p, key_start_2p, key_coin_a, key_coin_b;
reg key_tilt, key_test, key_reset, key_service, key_pause;

reg key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c, key_p1_d;
reg key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c, key_p2_d;

wire pressed = ps2_key[9];

always @(posedge clk_sys) begin
    reg old_state;
    old_state <= ps2_key[10];
    if ( old_state ^ ps2_key[10] ) begin
        casex ( ps2_key[8:0] )
            'h016 :  key_start_1p   <= pressed;            // 1
            'h01E :  key_start_2p   <= pressed;            // 2
            'h02E :  key_coin_a     <= pressed;            // 5
            'h036 :  key_coin_b     <= pressed;            // 6
            'h006 :  key_test       <= key_test ^ pressed; // f2
            'h004 :  key_reset      <= pressed;            // f3
            'h046 :  key_service    <= pressed;            // 9
            'h02C :  key_tilt       <= pressed;            // t
            'h04D :  key_pause      <= pressed;            // p

            'h175 :  key_p1_up      <= pressed;            // up
            'h172 :  key_p1_down    <= pressed;            // down
            'h16B :  key_p1_left    <= pressed;            // left
            'h174 :  key_p1_right   <= pressed;            // right
            'h014 :  key_p1_a       <= pressed;            // lctrl
            'h011 :  key_p1_b       <= pressed;            // lalt
            'h029 :  key_p1_c       <= pressed;            // spacebar
            'h012 :  key_p1_d       <= pressed;            // lshift

            'h02D :  key_p2_up      <= pressed;            // r
            'h02B :  key_p2_down    <= pressed;            // f
            'h023 :  key_p2_left    <= pressed;            // d
            'h034 :  key_p2_right   <= pressed;            // g
            'h01C :  key_p2_a       <= pressed;            // a
            'h01B :  key_p2_b       <= pressed;            // s
            'h015 :  key_p2_c       <= pressed;            // q
            'h01d :  key_p2_d       <= pressed;            // w
        endcase
    end
end

wire pll_locked;

wire clk_sys;
wire turbo_68k = status[15];
reg  clk_1_75M,clk_3_5M,clk_4M,clk_6M,clk_cpu_p,clk_cpu_s;

wire clk_72M;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_sys),
    .outclk_1(clk_72M),
    .locked(pll_locked)
);

assign    SDRAM_CLK = clk_72M;

localparam  CLKSYS=72;

reg  [7:0] clk_cpu_count;
reg  [7:0] clk12_count;
reg  [7:0] clk6_count;
reg  [7:0] clk4_count;
reg  [7:0] clk3_5_count;
reg  [7:0] clk1_75_count;

always @ (posedge clk_sys) begin
    clk_4M <= ( clk4_count == 0 );
    if ( clk4_count == 17 ) begin 
        clk4_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk4_count <= clk4_count + 1;
    end

    clk_6M <= ( clk6_count == 0 );
    if ( clk6_count == 11 ) begin // 11
        clk6_count <= 0;
    end else begin
        clk6_count <= clk6_count + 1;
    end

    // 12 / 14.4 MHZ
    clk_cpu_p <= ( clk12_count == 0 );
    if ( clk12_count == ( turbo_68k == 1 ? 4 : 5 ) ) begin   // 5
        clk12_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk12_count <= clk12_count + 1;
    end

    // clocks below change to fractional divider
    // clk_cpu_s <= ( clk_cpu_count == 0 );
    // if ( clk_cpu_count == 4 ) begin  // 4
    //    clk_cpu_count <= 0;
    // end else if ( pause_cpu == 0 ) begin
    //    clk_cpu_count <= clk_cpu_count + 1;
    // end

    // 14MHz
    // M = 7 / N = 36
    clk_cpu_s <= 0;
    if ( clk_cpu_count > 35 ) begin
        clk_cpu_s <= 1;
        clk_cpu_count <= clk_cpu_count - 29;
    end else begin
        clk_cpu_count <= clk_cpu_count + 7;
    end

    // M = 7 / N = 144
//    clk_3_5M <= 0;
//    if ( clk3_5_count > 143 ) begin
//        clk_3_5M <= 1;
//        clk3_5_count <= clk3_5_count - 136;
//    end else begin
//        clk3_5_count <= clk3_5_count + 7;
//    end

//    clk_3_5M <= ( clk3_5_count == 0 );
//    if ( clk3_5_count == 19 ) begin  // 3.6
//        clk3_5_count <= 0;
//    end else if ( pause_cpu == 0 ) begin
//        clk3_5_count <= clk3_5_count + 1;
//    end

    // M = 6 / N = 247
//    clk_1_75M <= 0;
//    if ( clk1_75_count > 246 ) begin
//        clk_1_75M <= 1;
//        clk1_75_count <= clk1_75_count - 240;
//    end else begin
//        clk1_75_count <= clk1_75_count + 6;
//    end

    clk_3_5M <= ( clk1_75_count == 0 || clk1_75_count == 20 );
    clk_1_75M <= ( clk1_75_count == 0 );
    if ( clk1_75_count == 39 ) begin  // 1.8
        clk1_75_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk1_75_count <= clk1_75_count + 1;
    end
end

wire    reset;
assign  reset = RESET | key_reset | status[0];

//////////////////////////////////////////////////////////////////
wire rotate_ccw = 0;
wire no_rotate = orientation | direct_video;
wire video_rotated;
reg  flip_init;

reg [23:0]     rgb;

wire hbl;
wire vbl;

wire [8:0] hc;
wire [8:0] vc;

wire hsync;
wire vsync;

reg hbl_delay, vbl_delay;

always @ ( posedge clk_6M ) begin
    hbl_delay <= hbl;
    vbl_delay <= vbl;
end

video_timing video_timing (
    .clk(clk_sys),
    .clk_pix(clk_6M),
    .hc(hc),
    .vc(vc),
    .refresh_mod(refresh_mod),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

// PAUSE SYSTEM
wire    pause_cpu;
wire    hs_pause;

// 8 bits per colour, 72MHz sys clk
pause #(8,8,8,72) pause
(
    .clk_sys(clk_sys),
    .reset(reset),
    .user_button(b_pause),
    .pause_request(hs_pause),
    .options(status[21:20]),
    .pause_cpu(pause_cpu),
    .dim_video(dim_video),
    .OSD_STATUS(OSD_STATUS),
    .r(rgb[23:16]),
    .g(rgb[15:8]),
    .b(rgb[7:0]),
    .rgb_out(rgb_pause_out)
);

wire [23:0] rgb_pause_out;
wire dim_video;

arcade_video #(256,24) arcade_video
(
        .*,

        .clk_video(clk_sys),
        .ce_pix(clk_6M),

        .RGB_in(rgb_pause_out),

        .HBlank(hbl_delay),
        .VBlank(vbl_delay),
        .HSync(hsync),
        .VSync(vsync),

        .fx(scan_lines)
);

/*
    Phase Accumulator Increments (Fractional Size 32, look up size 8 bit, total 40 bits)
    Increment Calculation - (Output Clock * 2 ^ Word Size) / Reference Clock
    Example
    NTSC = 3.579545
    PAL =  4.43361875
    W = 40 ( 32 bit fraction, 8 bit look up reference)
    Ref CLK = 42.954544 (This could us any clock)
    NTSC_Inc = 3.579545333 * 2 ^ 40 / 96 = 40997413706
*/

// SET PAL and NTSC TIMING
`ifdef MISTER_ENABLE_YC
    assign CHROMA_PHASE_INC = PALFLAG ? 40'd67705769010: 40'd54663037000;
    assign YC_EN =  status[22];
    assign PALFLAG = status[7];
`endif

wire flip = 0;

screen_rotate screen_rotate
(
    .CLK_VIDEO,
    .CE_PIXEL,

    .VGA_R,
    .VGA_G,
    .VGA_B,
    .VGA_HS,
    .VGA_VS,
    .VGA_DE,

    .rotate_ccw,
    .no_rotate,
    .flip,
    .video_rotated,

    .FB_EN,
    .FB_FORMAT,
    .FB_WIDTH,
    .FB_HEIGHT,
    .FB_BASE,
    .FB_STRIDE,
    .FB_VBL,
    .FB_LL,

    .DDRAM_CLK,
    .DDRAM_BUSY,
    .DDRAM_BURSTCNT,
    .DDRAM_ADDR,
    .DDRAM_DIN,
    .DDRAM_BE,
    .DDRAM_WE,
    .DDRAM_RD
);

reg [7:0] hc_del;

////////

reg         download_en;
reg [15:0]  download_index;
reg [26:0]  download_addr;
reg [7:0]   download_data;
reg         download_wr;
wire        download_wait;

// region       size    aw  b dw      ofs 
// --------------------------------------
// maincpu      80000   19  1 16    00000
// audiocpu     40000   18  1 16    80000
// oki1        100000   20  0  8   100000
// oki2         80000   19  0  8   200000
// scroll0      80000   19  3 64   280000
// scroll1      80000   19  3 64   300000
// scroll2      20000   17  3 64   380000
// sprites     100000   20  3 64   400000
// proms          200    9  0  8   500000
// mcu           2000   13  0  8         


// define functions used to decrypt cpu program
// bit reordering based on address range

// phantasm
function [15:0] swap_00(input [15:0] d);
begin
    swap_00 = { d[4'hd],d[4'he],d[4'hf],d[4'h0],d[4'h1],d[4'h8],d[4'h9],d[4'ha],d[4'hb],d[4'hc],d[4'h5],d[4'h6],d[4'h7],d[4'h2],d[4'h3],d[4'h4] };
end
endfunction

function [15:0] swap_01(input [15:0] d);
begin
    swap_01 = { d[4'hf],d[4'hd],d[4'hb],d[4'h9],d[4'h7],d[4'h5],d[4'h3],d[4'h1],d[4'he],d[4'hc],d[4'ha],d[4'h8],d[4'h6],d[4'h4],d[4'h2],d[4'h0] };
end
endfunction

function [15:0] swap_02(input [15:0] d);
begin
    swap_02 = { d[4'h0],d[4'h1],d[4'h2],d[4'h3],d[4'h4],d[4'h5],d[4'h6],d[4'h7],d[4'hb],d[4'ha],d[4'h9],d[4'h8],d[4'hf],d[4'he],d[4'hd],d[4'hc] };
end
endfunction

// astyanax
function [15:0] swap_10(input [15:0] d);
begin
    swap_10 = { d[4'hd],d[4'he],d[4'hf],d[4'h0],d[4'ha],d[4'h9],d[4'h8],d[4'h1],d[4'h6],d[4'h5],d[4'hc],d[4'hb],d[4'h7],d[4'h2],d[4'h3],d[4'h4] };
end
endfunction

function [15:0] swap_11(input [15:0] d);
begin
    swap_11 = { d[4'hf],d[4'hd],d[4'hb],d[4'h9],d[4'h7],d[4'h5],d[4'h3],d[4'h1],d[4'h8],d[4'ha],d[4'hc],d[4'he],d[4'h0],d[4'h2],d[4'h4],d[4'h6] };
end
endfunction

function [15:0] swap_12(input [15:0] d);
begin
    swap_12 = { d[4'h4],d[4'h5],d[4'h6],d[4'h7],d[4'h0],d[4'h1],d[4'h2],d[4'h3],d[4'hb],d[4'ha],d[4'h9],d[4'h8],d[4'hf],d[4'he],d[4'hd],d[4'hc] };
end
endfunction

// rodland
function [15:0] swap_20(input [15:0] d);
begin
    swap_20 = { d[4'hd],d[4'h0],d[4'ha],d[4'h9],d[4'h6],d[4'he],d[4'hb],d[4'hf],d[4'h5],d[4'hc],d[4'h7],d[4'h2],d[4'h3],d[4'h8],d[4'h1],d[4'h4] };
end
endfunction

function [15:0] swap_21(input [15:0] d);
begin
    swap_21 = { d[4'h4],d[4'h5],d[4'h6],d[4'h7],d[4'h0],d[4'h1],d[4'h2],d[4'h3],d[4'hb],d[4'ha],d[4'h9],d[4'h8],d[4'hf],d[4'he],d[4'hd],d[4'hc] };
end
endfunction

function [15:0] swap_22(input [15:0] d);
begin
    swap_22 = { d[4'hf],d[4'hd],d[4'hb],d[4'h9],d[4'hc],d[4'he],d[4'h0],d[4'h7],d[4'h5],d[4'h3],d[4'h1],d[4'h8],d[4'ha],d[4'h2],d[4'h4],d[4'h6] };
end
endfunction

function [15:0] swap_23(input [15:0] d);
begin
    swap_23 = { d[4'h4],d[4'h5],d[4'h1],d[4'h2],d[4'he],d[4'hd],d[4'h3],d[4'hb],d[4'ha],d[4'h9],d[4'h6],d[4'h7],d[4'h0],d[4'h8],d[4'hf],d[4'hc] };
end
endfunction

//localparam P47       = 0;  no encryption
//localparam PHANTASM  = 2;  phantasm
//localparam RODLAND   = 3;  rodland
//localparam RODLANDJ  = 4;  astyanax
//localparam SHINGEN   = 5;  phantasm
//localparam ASTYANAX  = 6;  astyanax
//localparam SOLDAM    = 7;  phantasm
//localparam SOLDAMJ   = 8;  astyanax
//localparam EDFP      = 9;  phantasm
//localparam INYOURF   = 10; phantasm
//localparam STDRAGON  = 11; phantasm
//localparam STDRAGONA = 12; phantasm
//localparam HACHOO    = 13; astyanax
//localparam PLUSALPH  = 14; astyanax
//localparam IGANINJU  = 15; phantasm
//localparam JITSUPRO  = 16; astyanax

function [15:0] cpu_decode(input [23:0] i, input [15:0] d);
begin
    if ( pcb == 0 || pcb == 1 ) begin
        // p47 & kickoff are not encrypted
        cpu_decode = d;
    end else if ( pcb == 2 || pcb == 5 || pcb == 7 || pcb == 9 || pcb == 10 || pcb == 11 || pcb == 12 || pcb == 15 ) begin
        // phantasm
        if          ( i < 20'h04000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_01( d ) : swap_00( d );
        end else if ( i < 20'h08000 ) begin
            cpu_decode = swap_02( d );
        end else if ( i < 20'h0c000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_01( d ) : swap_00( d );
        end else if ( i < 20'h10000 ) begin
            cpu_decode = swap_01( d );
        end else if ( i < 20'h20000 ) begin
            cpu_decode = swap_02( d );
        end else begin
            cpu_decode = d;
        end
    end else if ( pcb == 4 || pcb == 6 || pcb == 8 || pcb == 13 || pcb == 14 || pcb == 16 ) begin
        // astyanax
        if          ( i < 20'h04000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_11( d ) : swap_10( d );
        end else if ( i < 20'h08000 ) begin
            cpu_decode = swap_12( d );
        end else if ( i < 20'h0c000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_11( d ) : swap_10( d );
        end else if ( i < 20'h10000 ) begin
            cpu_decode = swap_11( d );
        end else if ( i < 20'h20000 ) begin
            cpu_decode = swap_12( d );
        end else begin
            cpu_decode = d;
        end
    end else if ( pcb == 3 ) begin
        // rod land
        if          ( i < 20'h04000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_21( d ) : swap_20( d );
        end else if ( i < 20'h08000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_23( d ) : swap_22( d );
        end else if ( i < 20'h0c000 ) begin
            cpu_decode = ( i[8] & i[5] & i[2] ) ? swap_21( d ) : swap_20( d );
        end else if ( i < 20'h10000 ) begin
            cpu_decode = swap_21( d );
        end else if ( i < 20'h20000 ) begin
            cpu_decode = swap_23( d );
        end else begin
            cpu_decode = d;
        end
    end
end
endfunction

function [19:0] spr_decode_1(input [19:0] a);
begin
    //int a = bitswap<20>(i, 19, 18, 17, 16, 15, 14,  3, 12, 11, 13, 9, 10, 7, 6, 5, 4,  8, 2, 1, 0);
    spr_decode_1 = { a[19:14], a[3],  a[12:11], a[13], a[9], a[10], a[7:4],  a[8], a[2:0] };
end
endfunction

function [19:0] spr_decode_2(input [19:0] a);
begin
//int a = bitswap<20>(i, 19, 18, 17, 16, 15, 14, 10, 12, 11,  8, 9,  3, 7, 6, 5, 4, 13, 2, 1, 0);
    spr_decode_2 = { a[19:14], a[10],  a[12:11], a[8], a[9], a[3], a[7:4],  a[13], a[2:0] };
end
endfunction

function [19:0] spr_decode_3(input [19:0] a);
begin
//int a = bitswap<20>(i, 19, 18, 17, 16, 15, 14, 8, 12, 11, 3, 9, 13, 7, 6, 5, 4, 10, 2, 1, 0);
    spr_decode_3 = { a[19:14], a[8],  a[12:11], a[3], a[9], a[13], a[7:4],  a[10], a[2:0] };
end
endfunction

// rearrange sprite data so 16 bit wide sprite is one 64 bit read
wire [26:0] sprite_ioctl_addr = { ioctl_addr[26:7], ioctl_addr[5:2], ioctl_addr[6], ioctl_addr[1:0] }; 

// address is decoded before it is rearranged for efficient 64 bit wide access
wire [19:0] decode_ioctl_addr = ( pcb == RODLAND ||  pcb == RODLANDJ ) ? spr_decode_1(ioctl_addr[19:0]) : 
                                ( pcb == STDRAGONA ) ? spr_decode_2(ioctl_addr[19:0]) :
                                spr_decode_3(ioctl_addr[19:0]);

wire [19:0] sprite_decode_ioctl_addr = { decode_ioctl_addr[19:7], decode_ioctl_addr[5:2], decode_ioctl_addr[6], decode_ioctl_addr[1:0] };

always @ (posedge clk_sys) begin
    download_en <= ioctl_download; 
    download_index <= ioctl_index;

    if ( ioctl_addr >= 26'h080000 && ioctl_addr < 26'h0A0000 ) begin
        // max 128k sound cpu
        sound_rom_addr <= ioctl_addr[16:1];
        sound_rom_w <= ioctl_wr & ioctl_addr[0];
        sound_rom_din[ { ~ioctl_addr[0], 3'b111 } -: 8 ] <= ioctl_dout;
        download_data <= ioctl_dout;
    end else if ( ioctl_addr >= 26'h280000 && ioctl_addr < 26'h300000 ) begin
        // rodland has encrypted scroll0 and sprite layers

        // scroll 0
        if ( pcb == RODLAND ||  pcb == RODLANDJ ) begin
            // TODO: ioctl address needs ofset corrected before the address decode is done
            download_addr <=  26'h280000 | sprite_decode_ioctl_addr;  // rodland
            // 6, 4, 5, 3, 7, 2, 1, 0
            download_data <= { ioctl_dout[6], ioctl_dout[4], ioctl_dout[5], ioctl_dout[3], ioctl_dout[7], ioctl_dout[2:0] };
        end else if ( pcb == STDRAGONA ) begin
            // TODO: ioctl address needs ofset corrected before the address decode is done
            download_addr <=  26'h280000 | sprite_decode_ioctl_addr;  // stdragona
            // 3,7,5,6,4,2,1,0
            download_data <= { ioctl_dout[3], ioctl_dout[7], ioctl_dout[5], ioctl_dout[6], ioctl_dout[4], ioctl_dout[2:0] };
        end else if ( pcb == JITSUPRO ) begin
            // TODO: ioctl address needs ofset corrected before the address decode is done
            download_addr <=  26'h280000 | sprite_decode_ioctl_addr;  // jitsupro
            // rom[i] = bitswap<8>(rom[i], 0x4, 0x3, 0x5, 0x7, 0x6, 0x2, 0x1, 0x0);
            download_data <= { ioctl_dout[4], ioctl_dout[3], ioctl_dout[5], ioctl_dout[7], ioctl_dout[6], ioctl_dout[2:0] };
        end else begin
            download_addr <= sprite_ioctl_addr;
            download_data <= ioctl_dout;
        end
    end else if ( ioctl_addr >= 26'h300000 && ioctl_addr < 26'h380000 ) begin
        // scroll 1
        download_addr <= sprite_ioctl_addr;
        download_data <= ioctl_dout;
    end else if ( ioctl_addr >= 26'h380000 && ioctl_addr < 26'h400000 ) begin
        // scroll 2
        download_addr <= sprite_ioctl_addr;
        download_data <= ioctl_dout;
    end else if ( ioctl_addr >= 26'h400000 && ioctl_addr < 26'h500000 ) begin
        // sprites

        // sprites are 128 bytes long - lower bits of ioctl_addr[26:7] will have the scroll_tile number
        // rearrange sprite data so entire 16 pixel width is loaded in one read
        // offsets.  ie byte 0x0040 in the rom gets written to 0x0004
        // 00,01,02,03,40,41,42,43
        // 04,05,06,07,44,45,46,47
        // 08,09,0A,0B,48,49,4A,4B

        if ( pcb == RODLAND ||  pcb == RODLANDJ ) begin
            download_addr <=  26'h400000 | sprite_decode_ioctl_addr;
            download_data <= { ioctl_dout[6], ioctl_dout[4], ioctl_dout[5], ioctl_dout[3], ioctl_dout[7], ioctl_dout[2:0] };
        end else if ( pcb == STDRAGONA ) begin
            // TODO: ioctl address needs ofset corrected before the address decode is done
            download_addr <=  26'h400000 | sprite_decode_ioctl_addr;  // stdragona
            download_data <= { ioctl_dout[3], ioctl_dout[7], ioctl_dout[5], ioctl_dout[6], ioctl_dout[4], ioctl_dout[2:0] };
        end else if ( pcb == JITSUPRO ) begin
            // TODO: ioctl address needs ofset corrected before the address decode is done
            download_addr <=  26'h400000 | sprite_decode_ioctl_addr;  // stdragona
            // 0x4, 0x3, 0x5, 0x7, 0x6, 0x2, 0x1, 0x0);
            download_data <= { ioctl_dout[4], ioctl_dout[3], ioctl_dout[5], ioctl_dout[7], ioctl_dout[6], ioctl_dout[2:0] };
        end else begin
            download_addr <= sprite_ioctl_addr;
            download_data <= ioctl_dout;
        end
    end else begin
        // address > 0x500000
        download_addr <= ioctl_addr;
        download_data <= ioctl_dout;
    end

    download_wr <= ioctl_wr;
end

reg [15:0]  sound_rom_addr;
reg [15:0]  sound_rom_din;
reg         sound_rom_w;

// CPU outputs
wire [23:0] m68kp_a;
wire m68kp_rw;          // Read = 1, Write = 0
wire m68kp_as_n;        // Address strobe
wire m68kp_lds_n;       // Lower byte strobe
wire m68kp_uds_n;       // Upper byte strobe
wire [2:0] m68kp_fc;    // Processor state
wire m68k_halted_n;     // Halt output
wire m68kp_e;
wire m68kp_reset_n_o;
wire m68kp_halted_n;
wire [15:0] m68kp_dout;


// CPU inputs
reg  [15:0] m68kp_din;

reg  m68kp_vpa_n;
reg  m68kp_dtack_n;
reg  m68kp_ipl0_n;
reg  m68kp_ipl1_n;
reg  m68kp_ipl2_n;

reg fx68p_phi1;

// fx68k requires twice the operating clock to generate phi phases
always @(posedge clk_sys) begin
    if ( clk_cpu_p == 1 ) begin
        fx68p_phi1 <= ~fx68p_phi1;
    end
end

fx68k main_cpu
(
    // input
    .clk( clk_cpu_p ),
    .enPhi1( ~fx68p_phi1 ),
    .enPhi2( fx68p_phi1),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68kp_rw),
    .ASn(m68kp_as_n),
    .LDSn(m68kp_lds_n),
    .UDSn(m68kp_uds_n),
    .E(m68kp_e),
    .VMAn(),
    .FC0(m68kp_fc[0]),
    .FC1(m68kp_fc[1]),
    .FC2(m68kp_fc[2]),
    .BGn(),
    .oRESETn(m68kp_reset_n_o),
    .oHALTEDn(m68kp_halted_n),

    // input
    .VPAn( m68kp_vpa_n ),
    .DTACKn( m68kp_dtack_n ),
    .BERRn(1'b1),
    .BRn(1'b1),
    .BGACKn(1'b1),

    .IPL0n(m68kp_ipl0_n),
    .IPL1n(m68kp_ipl1_n),
    .IPL2n(m68kp_ipl2_n),

    // busses
    .iEdb(m68kp_din),
    .oEdb(m68kp_dout),
    .eab(m68kp_a[23:1])
);

// CPU outputs
wire [23:0] m68ks_a;
wire m68ks_rw;            // Read = 1, Write = 0
wire m68ks_as_n;          // Address strobe
wire m68ks_lds_n;         // Lower byte strobe
wire m68ks_uds_n;         // Upper byte strobe
wire [2:0] m68ks_fc;      // Processor state
wire m68ks_e;
wire m68ks_reset_n_o;
wire m68ks_halted_n;
wire [15:0] m68ks_dout;

// CPU inputs
reg  [15:0] m68ks_din;
reg  sound_cpu_reset;
reg  m68ks_vpa_n;


//wire m68ks_dtack_n = m68ks_rom_cs ? !m68ks_rom_valid : 0;

reg  m68ks_ipl0_n;
reg  m68ks_ipl1_n;
reg  m68ks_ipl2_n;
reg  latch_irq_n ;

reg fx68s_phi1;

always @(posedge clk_sys) begin
    if ( clk_cpu_s == 1 ) begin
        fx68s_phi1 <= ~fx68s_phi1;
    end
	
	soft_reset <= screen_control[4];
	dip_flip <= screen_control[0];
end

// sound ICs and sound cpu are resetable via latch

reg soft_reset ;
reg dip_flip ;

fx68k sound_cpu
(
    // input
    .clk( clk_cpu_s ),
    .enPhi1( ~fx68s_phi1 ),
    .enPhi2( fx68s_phi1),

    .extReset(reset | soft_reset ),
    .pwrUp(reset | soft_reset),

    // output
    .eRWn(m68ks_rw),
    .ASn(m68ks_as_n),
    .LDSn(m68ks_lds_n),
    .UDSn(m68ks_uds_n),
    .E(m68ks_e),
    .VMAn(),
    .FC0(m68ks_fc[0]),
    .FC1(m68ks_fc[1]),
    .FC2(m68ks_fc[2]),
    .BGn(),
    .oRESETn(m68ks_reset_n_o),
    .oHALTEDn(m68ks_halted_n),

    // input
    .VPAn( m68ks_vpa_n ),
    .DTACKn( m68ks_dtack_n ),
    .BERRn(1'b1),
    .BRn(1'b1),
    .BGACKn(1'b1),

    .IPL0n(m68ks_ipl0_n),
    .IPL1n(m68ks_ipl1_n),
    .IPL2n(ym2151_irq_n & latch_irq_n), // m68ks_ipl2_n

    // busses
    .iEdb(m68ks_din),
    .oEdb(m68ks_dout),
    .eab(m68ks_a[23:1])
);

wire m68kp_ram_cs;

wire m68kp_p1_cs;
wire m68kp_p2_cs;
wire m68kp_dsw_cs;
wire m68kp_sys_cs;

wire m68kp_pal_cs;
wire m68kp_layer_cs;

wire m68kp_scr0_reg_cs;
wire m68kp_scr1_reg_cs;
wire m68kp_scr2_reg_cs;

wire m68kp_scr0_cs;
wire m68kp_scr1_cs;
wire m68kp_scr2_cs;
wire m68kp_spr_cs;
wire m68kp_spr_ctrl_cs;
wire m68kp_scr_ctrl_cs;

wire m68kp_latch0_cs;
wire m68kp_latch1_cs;

wire m68ks_latch0_cs;
wire m68ks_latch1_cs;
wire m68ks_ym2151_cs;
wire m68ks_oki0_cs;
wire m68ks_oki1_cs;
wire m68ks_ram_cs;

chip_select chip_select
(
    .clk(clk_sys),
    .pcb,
    // main cpu
    .m68kp_a,
    .m68kp_as_n,
    .m68kp_rw,

    // M68K selects
    .m68kp_rom_cs,
    .m68kp_ram_cs,

    .m68kp_p1_cs,
    .m68kp_p2_cs,
    .m68kp_dsw_cs,
    .m68kp_sys_cs,

    .m68kp_pal_cs,
    .m68kp_layer_cs,
    .m68kp_spr_cs,
    .m68kp_spr_ctrl_cs,
    .m68kp_scr_ctrl_cs,

    .m68kp_scr0_reg_cs,
    .m68kp_scr1_reg_cs,
    .m68kp_scr2_reg_cs,

    .m68kp_scr0_cs,
    .m68kp_scr1_cs,
    .m68kp_scr2_cs,

    .m68kp_latch0_cs,
    .m68kp_latch1_cs,

// sound cpu
    .m68ks_a,
    .m68ks_as_n,
    .m68ks_rw,

    .m68ks_rom_cs,
    .m68ks_latch0_cs,
    .m68ks_latch1_cs,
    .m68ks_ym2151_cs,
    .m68ks_oki0_cs,
    .m68ks_oki1_cs,
    .m68ks_ram_cs
);

reg   [1:0] hbl_sr;
reg         write_done_p;
reg         write_done_s;

reg  [15:0] sprite_control;
reg  [15:0] screen_control;
reg   [3:0] layer_enable;
reg         irq2_en;


/// 68k cpu
always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin

        m68kp_ipl0_n <= 1;
        m68kp_ipl1_n <= 1;
        m68kp_ipl2_n <= 1;

        m68ks_dtack_n <= 0;

        m68ks_ipl0_n <= 1;
        m68ks_ipl1_n <= 1;
        m68ks_ipl2_n <= 1;
        latch_irq_n  <= 1;

        m68kp_scr0_reg_x <= 0;
        m68kp_scr0_reg_y <= 0;
        m68kp_scr1_reg_x <= 0;
        m68kp_scr1_reg_y <= 0;
        m68kp_scr2_reg_x <= 0;
        m68kp_scr2_reg_y <= 0;

        layer_enable <= 0;
        sprite_control <= 0;
        sound_cpu_reset <= 0;

        mcu_en <= 0;
        mcu_ram[0] <= 0;
        mcu_ram[1] <= 0;
        mcu_ram[2] <= 0;
        mcu_ram[3] <= 0;
        mcu_ram[4] <= 0;
        
        irq2_en <= 0 ;
        
        write_done_p <= 0;
        write_done_s <= 0;

    end else begin
        // vblank handling
        hbl_sr <= { hbl_sr[0], hbl };
        if ( hbl_sr == 2'b01 ) begin // rising edge
            //  68k interrupts
            //  mcu may alter irq timing
            if ( pcb == IGANINJU ) begin
                if ( irq2_en == 1 ) begin
                    if ( vc == 8'hf0 ) begin  // vblank start
                        // irq 2
                        m68kp_ipl1_n <= 0;
                    end                
                end
            end else begin
                if ( vc == irq1_scanline ) begin  // vblank end
                    // irq 1
                    m68kp_ipl0_n <= 0;
                end else if ( vc == 8'h80 ) begin  // mid playfield
                    // irq 3
                    m68kp_ipl0_n <= 0;
                    m68kp_ipl1_n <= 0;
                end else if ( vc == 8'hf0 ) begin  // vblank start
                    // irq 2
                    m68kp_ipl1_n <= 0;
                end
            end
        end
        if ( clk_cpu_p == 1 ) begin
//            m68kp_dtack_n <= m68kp_rom_cs ? !m68kp_rom_valid : 0; 
            if ( m68kp_as_n == 0 && m68kp_fc == 3'b111 ) begin
                m68kp_ipl0_n <= 1;
                m68kp_ipl1_n <= 1;
                m68kp_ipl2_n <= 1;
            end
            
            if ( m68kp_as_n == 1 ) begin
                write_done_p <= 0;
            end
            
            if ( m68kp_rw == 1 ) begin
                // reads
                m68kp_din <= m68kp_rom_cs      ? mcu_rom : // m68kp_rom_dout :
                             m68kp_ram_cs      ? m68kp_ram_dout :
                             m68kp_spr_cs      ? sprite_dout  :
                             m68kp_latch1_cs   ? m68ks_latch1 :
                             m68kp_scr0_cs     ? m68kp_scroll0_dout :
                             m68kp_scr1_cs     ? m68kp_scroll1_dout :
                             m68kp_scr2_cs     ? m68kp_scroll2_dout :
                             m68kp_pal_cs      ? m68kp_palette_dout :
                             m68kp_p1_cs       ? p1 :
                             m68kp_p2_cs       ? p2 :
                             m68kp_dsw_cs      ? dsw :
                             m68kp_sys_cs      ? system :
                             m68kp_scr0_reg_cs ? m68kp_scr0_reg :
                             m68kp_scr1_reg_cs ? m68kp_scr1_reg :
                             m68kp_scr1_reg_cs ? m68kp_scr2_reg :
                             m68kp_spr_ctrl_cs ? sprite_control :
                             16'h0000;
            end else begin
                
                if ( write_done_p == 0 ) begin // falling edge
                    write_done_p <= 1 ;

                    // mcu handling 
                    if ( pcb == ASTYANAX || pcb == HACHOO || pcb == PLUSALPH || pcb == JITSUPRO && m68kp_rom_cs == 1 && m68kp_a[19:16] == 4'h2 ) begin
                        if (mcu_ram[0] == 16'h00ff && mcu_ram[1] == 16'h0055 && mcu_ram[2] == 16'h00aa && mcu_ram[3] == 16'h0000 ) begin
                            mcu_en <= 1 ;
                        end else begin
                            mcu_en <= 0 ;
                        end
                        mcu_ram[m68kp_a[3:1]] <= m68kp_dout;
                    end else if ( pcb == STDRAGON || pcb == STDRAGONA && m68kp_rom_cs == 1 && m68kp_a[19:16] == 4'h2 ) begin
                        if (mcu_ram[0] == 16'h0000 && mcu_ram[1] == 16'h0055 && mcu_ram[2] == 16'h00aa && mcu_ram[3] == 16'h00ff ) begin
                            mcu_en <= 1 ;
                        end else begin
                            mcu_en <= 0 ;
                        end
                        mcu_ram[m68kp_a[3:1]] <= m68kp_dout;
                    end else if ( pcb == IGANINJU && m68kp_rom_cs == 1 && m68kp_a[19:12] == 8'h2f ) begin
                        if (mcu_ram[0] == 16'h0000 && mcu_ram[1] == 16'h0055 && mcu_ram[2] == 16'h00aa && mcu_ram[3] == 16'h00ff ) begin
                            mcu_en <= 1 ;
                        end else begin
                            mcu_en <= 0 ;
                        end
                        mcu_ram[m68kp_a[3:1]] <= m68kp_dout;
                    end
                    
                    // writes
                    
                    if ( pcb == IGANINJU && m68kp_a[23:0] == 24'h0f0000 ) begin
                        irq2_en <= ( m68kp_dout != 0 ) ;

                    end

                    if ( m68kp_latch0_cs == 1 ) begin
                        // sound latch
                        m68kp_latch0 <= m68kp_dout;
                        // assert irq 4 on sound cpu 
                        // some games disable interrupts on audio cpu with the interrupt mask
                        latch_irq_n <= 0 ;
                    end
                    
                    if ( m68kp_spr_ctrl_cs == 1 ) begin
                        sprite_control <= m68kp_dout;
                    end
                    
                    if ( m68kp_scr_ctrl_cs == 1 ) begin
                        screen_control <= m68kp_dout;
                    end
                    
                    // todo: implement prom decoder.
                    //       decoded layer priority loaded from mra
                    if ( m68kp_layer_cs == 1 ) begin
                        // low 5 bytes are layer priority order
                        layer_prom <= prom[m68kp_dout[11:8]][19:0];
                        layer_enable <= m68kp_dout[3:0];
                    end
                    
                    if ( m68kp_scr0_reg_cs == 1 ) begin
                        case ( m68kp_a[2:1] )
                            0: begin
                                if ( m68kp_dout == 16'h580 ) begin
                                    m68kp_scr0_reg_x <= m68kp_scr0_reg_x + 1 ;
                                end else begin
                                    m68kp_scr0_reg_x <= m68kp_dout;
                                end
                            end
                            1: m68kp_scr0_reg_y <= m68kp_dout;
                            2: m68kp_scr0_reg_mode <= m68kp_dout;
                        endcase
                    end
                    
                    if ( m68kp_scr1_reg_cs == 1 ) begin
                        case ( m68kp_a[2:1] )
                            0: m68kp_scr1_reg_x <= m68kp_dout;
                            1: m68kp_scr1_reg_y <= m68kp_dout;
                            2: m68kp_scr1_reg_mode <= m68kp_dout;
                        endcase
                    end
                    
                    if ( m68kp_scr2_reg_cs == 1 ) begin
                        case ( m68kp_a[2:1] )
                            0: m68kp_scr2_reg_x <= m68kp_dout;
                            1: m68kp_scr2_reg_y <= m68kp_dout;
                            2: m68kp_scr2_reg_mode <= m68kp_dout;
                        endcase
                    end
                end
            end
        end        // clk_cpu_p
                   // m68ks_rom_valid forced hi. no need for rom dtack since bram is used
                   // dtack is for audio
        m68ks_dtack_n <= ( m68ks_ym2151_cs & ym2151_dout[7] );
        
        if ( m68ks_ym2151_cs == 0 || m68ks_rw == 1 ) begin
            ym2151_w <= 0;
        end
        
        if ( clk_cpu_s == 1 ) begin
        
            if ( m68ks_as_n == 0 && m68ks_fc == 3'b111 ) begin
                latch_irq_n <= 1;
            end
            
            if ( m68kp_as_n == 1 ) begin
                write_done_s <= 0;
            end

            oki0_w <= 0;
            oki1_w <= 0;
            
            if ( m68ks_rw == 1 ) begin
                // reads
                m68ks_din <= m68ks_rom_cs    ? m68ks_rom_dout :
                             m68ks_ram_cs    ? m68ks_ram_dout :
                             m68ks_latch0_cs ? m68kp_latch0   :
                             m68ks_oki0_cs   ? { 8'h00, ( ( pcb == HACHOO ) ?  oki0_dout : 8'h00 ) } : // oki0_dout
                             m68ks_oki1_cs   ? { 8'h00, ( ( pcb == HACHOO ) ?  oki1_dout : 8'h00 ) } : // oki1_dout
                             m68ks_ym2151_cs ? { 8'h00, ym2151_dout } :
                             16'h0000;
            end else begin
                if ( write_done_s == 0 ) begin // falling edge
                    write_done_s <= 1 ;

                    // writes
                    if ( m68ks_latch1_cs == 1 && m68ks_as_n == 0 ) begin
                        // sound latch
                        m68ks_latch1 <= m68ks_dout;
                    end
                    
                    if ( m68ks_ym2151_cs == 1 && m68ks_as_n == 0 ) begin
                        ym2151_din <= m68ks_dout[7:0];
                        ym2151_addr <= m68ks_a[1];
                        ym2151_w <= 1;
                    end
                    
                    // if ( m68ks_oki0_cs == 1 && m68ks_as_n == 0) begin
                    //    oki0_din <= m68ks_dout[7:0];
                    //    oki0_w <= 1;
                    // end
                    
                    // if ( m68ks_oki1_cs == 1 && m68ks_as_n == 0) begin
                    //    oki1_din <= m68ks_dout[7:0];
                    //    oki1_w <= 1;
                    // end
                end
            end
        end        // clk_cpu_s
    end            // reset
end                // always

// mcu hack
always @ * begin
    mcu_rom = m68kp_rom_dout;
    if ( pcb == ASTYANAX || pcb == HACHOO || pcb == PLUSALPH || pcb == JITSUPRO ) begin
        if ( mcu_en == 1 && m68kp_a[23:0] >= 24'h03FFC0 && m68kp_a[23:0] < 24'h040000 ) begin
            mcu_rom = 16'h889e;
        end
    end else if ( pcb == STDRAGON ) begin
        if ( mcu_en == 1 && m68kp_a[23:0] >= 24'h00CF80 && m68kp_a[23:0] < 24'h00CF82 ) begin
            mcu_rom = 16'h835d;
        end
    end else if ( pcb == STDRAGONA ) begin
        if ( mcu_en == 1 && m68kp_a[23:0] >= 24'h00CFC0 && m68kp_a[23:0] < 24'h00D000 ) begin
            mcu_rom = 16'h835d;
        end
    end else if ( pcb == IGANINJU ) begin
        if ( mcu_en == 1 && m68kp_a[23:0] >= 24'h2F000 && m68kp_a[23:0] < 24'h2F040 ) begin            
            mcu_rom = 16'h835d;
        end
    end
end

reg          mcu_en;
wire [15:0]  mcu_rom;
reg  [15:0]  mcu_ram [0:15];

reg  m68ks_dtack_n;

reg [15:0] m68kp_latch0;
reg [15:0] m68ks_latch1;

reg         ym2151_w;
reg         ym2151_addr;
reg   [7:0] ym2151_din;
wire  [7:0] ym2151_dout;
wire [15:0] ym_left;
wire [15:0] ym_right;
wire        ym2151_irq_n;

assign      AUDIO_S = 1;

jt51 ym2151
(
    .rst      ( reset | soft_reset ), // reset
    .clk      ( clk_sys            ), // main clock
    .cen_p1   ( clk_1_75M          ), // 1.75mhz, half clock
    .cs_n     ( 0                  ), // chip select
    .wr_n     ( ~ym2151_w          ), // write
    .a0       ( ym2151_addr        ),
    .din      ( ym2151_din         ), // data in
    .dout     ( ym2151_dout        ), // data out ym2151_dout
    .ct1      (                    ),
    .ct2      (                    ),
    .irq_n    ( ym2151_irq_n       ),
    // Low resolution output (same as real chip)
    .sample   (                    ), // marks new output sample
    .left     ( ym_left            ),
    .right    ( ym_right           ),
    // Full resolution output
    .xleft    (                    ),
    .xright   (                    ),
    // unsigned outputs for sigma delta converters, full resolution
    .dacleft  (                    ),
    .dacright (                    )
);

reg   [7:0] oki0_din;
reg   [7:0] oki0_data;
wire  [7:0] oki0_dout;
reg         oki0_w;
wire signed [13:0] oki0_sample;
reg         oki0_rom_cs;
reg  [17:0] oki0_rom_prev_addr;
reg         oki0_rom_done;
wire        oki0_sample_clk;


always @ ( posedge clk_sys ) begin
    if ( reset == 1 ) begin
        oki0_rom_cs <= 0;
        oki1_rom_cs <= 0;
        oki0_rom_prev_addr <= 16'hffff;
        oki1_rom_prev_addr <= 16'hffff;
    end else begin
        if ( oki0_rom_valid == 1 ) begin
            oki0_rom_done <= 1;
        end else if ( clk_4M == 1 ) begin
            oki0_rom_done <= 0;
        end
        if ( oki1_rom_valid == 1 ) begin
            oki1_rom_done <= 1;
            oki1_data <= oki1_rom_dout;
        end else if ( clk_4M == 1 ) begin
            oki1_rom_done <= 0;
        end
        if ( oki0_rom_prev_addr != oki0_rom_addr ) begin
            oki0_rom_prev_addr <= oki0_rom_addr;
            oki0_rom_cs <= 1;
        end
        if ( oki0_rom_valid == 1 ) begin
            oki0_data <= oki0_rom_dout;
            oki0_rom_cs <= 0;
        end
        if ( oki1_rom_prev_addr != oki1_rom_addr ) begin
            oki1_rom_prev_addr <= oki1_rom_addr;
            oki1_rom_cs <= 1;
        end
        if ( oki1_rom_valid == 1 ) begin
            oki1_rom_cs <= 0;
        end
    end
end

// data in is latched on falling wrn
jt6295 #(.INTERPOL(0)) oki_0
(
    .rst( reset | soft_reset                     ),
    .clk( clk_sys                                ),
    .cen( clk_4M                                 ),
    .ss( 1'b1                                    ),
    // CPU interface
    // .wrn( ~oki0_w                             ), //  active low
    // .din( oki0_din                            ),
    .wrn( m68ks_as_n | m68ks_rw | !m68ks_oki0_cs ), //  active low  ~oki0_w
    .din( m68ks_dout[7:0]                        ), // oki0_din
    .dout( oki0_dout                             ),
    // ROM interface
    .rom_addr( oki0_rom_addr                     ),
    .rom_data( oki0_data                         ),
    .rom_ok( oki0_rom_done                       ),
    // Sound output
    .sound( oki0_sample                          ),
    .sample( oki0_sample_clk                     )
);

reg   [7:0] oki1_din;
reg   [7:0] oki1_data;
wire  [7:0] oki1_dout;
reg         oki1_w;
wire signed [13:0] oki1_sample;
reg         oki1_rom_cs;
reg  [17:0] oki1_rom_prev_addr;
reg         oki1_rom_done;
wire        oki1_sample_clk;

jt6295 #(.INTERPOL(0)) oki_1
(
    .rst( reset | soft_reset                     ),
    .clk( clk_sys                                ),
    .cen( clk_4M                                 ),
    .ss( 1'b1                                    ),
    // CPU interface
    // .wrn( ~oki1_w            ), //  active low
    // .din( oki1_din           ),
    .wrn( m68ks_as_n | m68ks_rw | !m68ks_oki1_cs ), //  active low  ~oki0_w
    .din( m68ks_dout[7:0]                        ), // oki0_din
    .dout( oki1_dout                             ),
    // ROM interface
    .rom_addr( oki1_rom_addr                     ),
    .rom_data( oki1_data                         ),
    .rom_ok( oki1_rom_done                       ),
    // Sound output
    .sound( oki1_sample                          ),
    .sample( oki1_sample_clk                     )
);

//wire      audio_en   = status[11];       // audio enable
wire      stereo_en  = status[12];       // mono to stereo toggle

wire [1:0] pcm0_level  = status[44:43]; // oki0 audio mix
wire [1:0] pcm1_level  = status[46:45]; // oki1 audio mix
wire [1:0] fm_level    = status[48:47]; // opm audio mix

reg  [7:0] pcm0_mult;
reg  [7:0] pcm1_mult;
reg  [7:0] fm_mult;

// set the multiplier for each channel from menu

always @( posedge clk_sys, posedge reset ) begin
    if (reset) begin
        pcm0_mult<=0;
        pcm1_mult<=0;
        fm_mult<=0;
    end else begin
    case( pcm0_level )
        0: pcm0_mult <= 8'h07;    // 44%
        1: pcm0_mult <= 8'h08;    // 50%
        2: pcm0_mult <= 8'h0c;    // 75%
        3: pcm0_mult <= 8'h0;     // 0%
    endcase

    case( pcm1_level )
        0: pcm1_mult <= 8'h06;    // 37.5%
        1: pcm1_mult <= 8'h08;    // 50%
        2: pcm1_mult <= 8'h0c;    // 75%
        3: pcm1_mult <= 8'h0;     // 0%
    endcase

    case( fm_level )
        0: fm_mult <= 8'h0c;    // 75%
        1: fm_mult <= 8'h08;    // 50%
        2: fm_mult <= 8'h04;    // 25%
        3: fm_mult <= 8'h0;     // 0%
    endcase
    end
end

wire signed [15:0] mono;
wire signed [15:0] left_stereo;
wire signed [15:0] right_stereo;

wire signed [15:0] left_mixed;
wire signed [15:0] right_mixed;

assign left_mixed  = ( stereo_en == 0 ) ? mono : left_stereo;
assign right_mixed = ( stereo_en == 0 ) ? mono : right_stereo;

jtframe_mixer #(.W0(16), .W1(14), .W2(14), .WOUT(16)) u_mix_left(
    .rst    ( reset        ),
    .clk    ( clk_sys      ),
    .cen    ( 1'b1         ),
    // input signals
    .ch0    ( ym_left      ),
    .ch1    ( oki0_sample  ),
    .ch2    ( oki1_sample  ),
    .ch3    ( 16'd0        ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( fm_mult      ),
    .gain1  ( pcm0_mult    ),
    .gain2  ( pcm1_mult    ),
    .gain3  ( 8'd0         ),
    .mixed  ( left_stereo  ),
    .peak   (              )
);

jtframe_mixer #(.W0(16), .W1(14), .W2(14), .WOUT(16)) u_mix_right(
    .rst    ( reset        ),
    .clk    ( clk_sys      ),
    .cen    ( 1'b1         ),
    // input signals
    .ch0    ( ym_right     ),
    .ch1    ( oki0_sample  ),
    .ch2    ( oki1_sample  ),
    .ch3    ( 16'd0        ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( fm_mult      ),
    .gain1  ( pcm0_mult    ),
    .gain2  ( pcm1_mult    ),
    .gain3  ( 8'd0         ),
    .mixed  ( right_stereo ),
    .peak   (              )
);

jtframe_mixer #(.W0(16), .W1(16), .WOUT(16)) u_mix_mono(
    .rst    ( reset        ),
    .clk    ( clk_sys      ),
    .cen    ( 1'b1         ),
    // input signals
    .ch0    ( left_stereo  ),
    .ch1    ( right_stereo ),
    .ch2    (              ),
    .ch3    (              ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( 8'h0b        ),    // 68.7%
    .gain1  ( 8'h0b        ),    // 68.7%
    .gain2  ( 8'd0         ),
    .gain3  ( 8'd0         ),
    .mixed  ( mono         ),
    .peak   (              )
);

always @ * begin
    if ( pause_cpu == 1 ) begin
        AUDIO_L <= 0;
        AUDIO_R <= 0;
    end else begin
        // mix audio
        AUDIO_L <= left_mixed;
        AUDIO_R <= right_mixed;
    end
end

reg   [9:0] line_buf_addr_r;
reg   [9:0] line_buf_addr_w;
reg         line_buf_w;
reg  [15:0] line_buf_din;
wire [15:0] line_buf_dout;

// scroll line buffer
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) scroll_buffer_ram
(
    .clock_a ( clk_sys ),
    .address_a ( line_buf_addr_w ),
    .wren_a ( line_buf_w ),
    .data_a ( line_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),
    .wren_b ( 0 ),
    .q_b ( line_buf_dout )
    );

reg sprite_overrun; // debug

reg   [4:0] scroll_state;
reg   [8:0] scroll_x_pos;
reg   [3:0] scroll_x_ofs;
reg   [3:0] sprite_ord;
reg         sprite_ord_en;

reg  [16:0] scroll_tile;

reg  [63:0] scroll_pix_data;
reg  [15:0] sprite_control_latch;

wire  [3:0] scroll_pen = scroll_pix_data[ {~scroll_x_ofs[3:0], 2'b11} -: 4 ] ; // [63:60]...[3:0]
reg   [3:0] scroll_colour;

// sprite stuff commented out.
// each scroll_tile layer can be one of 8 layouts.  still todo

//reg [1:0] scroll_layer;
reg scroll_size;

wire [15:0] scroll0_x = scroll_x_pos + m68kp_scr0_reg_x;
wire [15:0] scroll1_x = scroll_x_pos + m68kp_scr1_reg_x;
wire [15:0] scroll2_x = scroll_x_pos + m68kp_scr2_reg_x;

wire [15:0] scroll0_y = ( dip_flip == 0 ? vc : 255 - vc ) + m68kp_scr0_reg_y;
wire [15:0] scroll1_y = ( dip_flip == 0 ? vc : 255 - vc ) + m68kp_scr1_reg_y;
wire [15:0] scroll2_y = ( dip_flip == 0 ? vc : 255 - vc ) + m68kp_scr2_reg_y;

// todo: **** refactor so each scroll layer is a module
// ( dip_flip == 0 )

reg   [2:0] layer_idx;
reg  [19:0] layer_prom; /// [0:15] = '{20'h04132, 20'h02413, 20'h03142};
reg   [3:0] scroll_layer;
reg         first_layer;

reg    [7:0] max_count;
reg   [31:0] req_count;
reg   [31:0] wait_count;
reg   [31:0] wait_total;
reg   [31:0] max_wait;
reg          prev_cs;

always @ ( posedge clk_sys ) begin
    if ( reset == 1 ) begin
        req_count <= 0;
        max_wait <= 0;
        wait_total <= 0;
        prev_cs <= 0;
    end else begin
        if ( m68kp_rom_cs == 1 ) begin
            if ( prev_cs == 0 ) begin
                prev_cs <= 1;
                req_count <= req_count + 1;
            end
            if ( m68kp_rom_valid == 0 ) begin
                wait_count <= wait_count + 1;
                wait_total <= wait_total + 1;
            end
        end else begin
            wait_count <= 0;
            prev_cs <= 0;
            if ( wait_count > max_wait ) begin
                max_wait <= wait_count;
            end
        end
    end
end

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        scroll_state <= 0;
        sprite_overrun <= 0;
        sprite_rom_cs <= 0;
        scroll_size <= 0;
        max_count <= 0;
    end else begin

        if ( scroll_state == 0 && hc == 0 && vc >= 15 && vc < 240 ) begin
            // init
            scroll_state <= 1; 
            // setup clearing line buffer
            line_buf_din <= 16'h8fff;
            scroll_x_pos <= 0;
            layer_idx <= 4;
            first_layer <= 1;
        end else if ( scroll_state == 1 )  begin
            line_buf_w <= 1;
            line_buf_addr_w <= { ~vc[0], scroll_x_pos };
            if ( scroll_x_pos > 256 ) begin
                line_buf_w <= 0;
                scroll_state <= 2;
            end
            scroll_x_pos <= scroll_x_pos + 1;
        end else if ( scroll_state == 2 ) begin
            scroll_layer = layer_prom[{ layer_idx, 2'b11 } -: 4];
            scroll_x_pos <= 0;
            scroll_state <= 3;
        end else if ( scroll_state == 3 ) begin
            if ( scroll_layer > 2 ) begin
                // sprite layer?
                scroll_state <= 18;
            end else if ( layer_enable[scroll_layer[1:0]] == 0 && layer_idx < 4 ) begin
                // disabled?
                scroll_state <= 18;
            end else begin
                case ( scroll_layer )
                    // [12:0] scroll0_addr_r
                    0: begin
                        case ( { m68kp_scr0_reg_mode[4], m68kp_scr0_reg_mode[1:0] } )
                            // 16x16
                            0: scroll0_addr_r <= { scroll0_y[   8], scroll0_x[11:4], scroll0_y[7:4] };  //[0][0] 4096x512
                            1: scroll0_addr_r <= { scroll0_y[ 9:8], scroll0_x[10:4], scroll0_y[7:4] };  //[0][1] 2048x1024
                            2: scroll0_addr_r <= { scroll0_y[10:8], scroll0_x[ 9:4], scroll0_y[7:4] };  //[0][2] 1024x2048
                            3: scroll0_addr_r <= { scroll0_y[11:8], scroll0_x[ 8:4], scroll0_y[7:4] };  //[0][3] 512x4096

                            // 8x8
                            4: scroll0_addr_r <= {                  scroll0_x[10:3], scroll0_y[7:3] };  //[1][0] 2048x256
                            5: scroll0_addr_r <= { scroll0_y[8],    scroll0_x[ 9:3], scroll0_y[7:3] };  //[1][1] 1024x512
                            6: scroll0_addr_r <= { scroll0_y[8],    scroll0_x[ 8:3], scroll0_y[7:3] };  //[1][2] 1024x512
                            7: scroll0_addr_r <= { scroll0_y[9:8],  scroll0_x[ 7:3], scroll0_y[7:3] };  //[1][3] 512x1024
                        endcase
                    end
                    1: begin
                        case ( { m68kp_scr1_reg_mode[4], m68kp_scr1_reg_mode[1:0] } )
                            // 16x16
                            0: scroll1_addr_r <= { scroll1_y[   8], scroll1_x[11:4], scroll1_y[7:4] };
                            1: scroll1_addr_r <= { scroll1_y[ 9:8], scroll1_x[10:4], scroll1_y[7:4] };
                            2: scroll1_addr_r <= { scroll1_y[10:8], scroll1_x[ 9:4], scroll1_y[7:4] };
                            3: scroll1_addr_r <= { scroll1_y[11:8], scroll1_x[ 8:4], scroll1_y[7:4] };

                            // 8x8
                            4: scroll1_addr_r <= {                  scroll1_x[10:3], scroll1_y[7:3] };
                            5: scroll1_addr_r <= { scroll1_y[8],    scroll1_x[ 9:3], scroll1_y[7:3] };
                            6: scroll1_addr_r <= { scroll1_y[8],    scroll1_x[ 8:3], scroll1_y[7:3] };
                            7: scroll1_addr_r <= { scroll1_y[9:8],  scroll1_x[ 7:3], scroll1_y[7:3] };
                        endcase
                    end
                    2: begin
                        case ( { m68kp_scr2_reg_mode[4], m68kp_scr2_reg_mode[1:0] } )
                            // 16x16
                            0: scroll2_addr_r <= { scroll2_y[   8], scroll2_x[11:4], scroll2_y[7:4] };
                            1: scroll2_addr_r <= { scroll2_y[ 9:8], scroll2_x[10:4], scroll2_y[7:4] };
                            2: scroll2_addr_r <= { scroll2_y[10:8], scroll2_x[ 9:4], scroll2_y[7:4] };
                            3: scroll2_addr_r <= { scroll2_y[11:8], scroll2_x[ 8:4], scroll2_y[7:4] };

                            // 8x8
                            4: scroll2_addr_r <= {                  scroll2_x[10:3], scroll2_y[7:3] };
                            5: scroll2_addr_r <= { scroll2_y[8],    scroll2_x[ 9:3], scroll2_y[7:3] };
                            6: scroll2_addr_r <= { scroll2_y[8],    scroll2_x[ 9:3], scroll2_y[7:3] };
                            7: scroll2_addr_r <= { scroll2_y[9:8],  scroll2_x[ 8:3], scroll2_y[7:3] };
                        endcase
                    end
                endcase
                scroll_state <= 4;
            end
        end else if ( scroll_state == 4 ) begin
            // address ready
            scroll_state <= 5;
        end else if ( scroll_state == 5 ) begin
            // data ready
            case ( scroll_layer )
                0: begin
                    scroll_tile <= scroll0_dout[11:0];
                    scroll_colour <= scroll0_dout[15:12];
                end
                1: begin
                    scroll_tile <= (m68kp_scr1_reg_mode[4] == 1 && (pcb == 7 || pcb == 8 )) ? { scroll1_dout[11:0], 2'b0 } : scroll1_dout[11:0];
                    //scroll_tile <= scroll1_dout[11:0];
                    scroll_colour <= scroll1_dout[15:12];
                end
                2: begin
                    scroll_tile <= scroll2_dout[11:0];
                    scroll_colour <= scroll2_dout[15:12];
                end
            endcase
            scroll_state <= 6;
        end else if ( scroll_state == 6 ) begin
            line_buf_w <= 0;
            case ( scroll_layer )
                0: begin
                    if ( m68kp_scr0_reg_mode[4] == 0 ) begin
                        // 16x16
                        scroll0_rom_addr <= { scroll_tile[16:0], scroll0_y[3:0] }; 
                        scroll_x_ofs <= 0;
                    end else begin
                        // 8x8
                        scroll0_rom_addr <= { scroll_tile[16:2], scroll_tile[0], scroll0_y[2:0] };
                        scroll_x_ofs <= { scroll_tile[1], 3'b0 };
                    end
                    scroll_x_ofs <= 0 ;
                    scroll_size <= !m68kp_scr0_reg_mode[4];
                    scroll0_rom_cs <= 1;
                end
                1: begin
                    if ( m68kp_scr1_reg_mode[4] == 0 ) begin
                        scroll1_rom_addr <= { scroll_tile[16:0], scroll1_y[3:0] }; 
                        scroll_x_ofs <= 0;
                    end else begin
                        scroll1_rom_addr <= { scroll_tile[16:2], scroll_tile[0], scroll1_y[2:0] };
                        scroll_x_ofs <= { scroll_tile[1], 3'b0 };
                    end
                    scroll_size <= !m68kp_scr1_reg_mode[4];
                    scroll1_rom_cs <= 1;
                end
                2: begin
                    if ( m68kp_scr2_reg_mode[4] == 0 ) begin
                        scroll2_rom_addr <= { scroll_tile[16:0], scroll2_y[3:0] }; 
                        scroll_x_ofs <= 0;
                    end else begin
                        scroll2_rom_addr <= { scroll_tile[16:2], scroll_tile[0], scroll2_y[2:0] };
                        scroll_x_ofs <= { scroll_tile[1], 3'b0 };
                    end
                    scroll_size <= !m68kp_scr2_reg_mode[4];
                    scroll2_rom_cs <= 1;
                end
            endcase
            //sprite_rom_cs <= 1;
            scroll_state <= 11;
        end else if ( scroll_state == 11 ) begin
            // wait for sprite bitmap data
            if (  | {scroll0_rom_valid,scroll1_rom_valid,scroll2_rom_valid} == 1 ) begin
                // bitmap data valid.  deassert read
                scroll0_rom_cs <= 0;
                scroll1_rom_cs <= 0;
                scroll2_rom_cs <= 0;
                case ( scroll_layer )
                    0: scroll_pix_data <= scroll0_rom_dout;
                    1: scroll_pix_data <= scroll1_rom_dout;
                    2: scroll_pix_data <= scroll2_rom_dout;
                endcase
                scroll_state <= 12;
            end
        end else if ( scroll_state == 12 ) begin
            scroll_state <= 13;
        end else if ( scroll_state == 13 ) begin
            // write to the line buffer
            case ( scroll_layer )
                0: line_buf_addr_w <= { ~vc[0], scroll_x_pos - { scroll_size & m68kp_scr0_reg_x[3],  m68kp_scr0_reg_x[2:0] } };
                1: line_buf_addr_w <= { ~vc[0], scroll_x_pos - { scroll_size & m68kp_scr1_reg_x[3],  m68kp_scr1_reg_x[2:0] } };
                2: line_buf_addr_w <= { ~vc[0], scroll_x_pos - { scroll_size & m68kp_scr2_reg_x[3],  m68kp_scr2_reg_x[2:0] } };
            endcase

            line_buf_w <= ( first_layer == 1 ) || (scroll_pen != 15); //don't write if 15 - transparent

            line_buf_din <= { 3'b0, layer_idx , scroll_layer[1:0], scroll_colour, scroll_pen };

            scroll_x_pos <= scroll_x_pos + 1;

            //if ( scroll_x_ofs < 15 ) begin
            if ( { ( scroll_size & scroll_x_ofs[3] ), scroll_x_ofs[2:0] } < { scroll_size , 3'b111 } ) begin
                scroll_x_ofs <= scroll_x_ofs + 1;
            end else begin
                scroll_state <= 17;
            end
        end else if ( scroll_state == 17) begin
            line_buf_w <= 0;
            if ( scroll_x_pos < 272 ) begin
                scroll_state <= 3;
            end else begin
                scroll_state <= 18;
            end
        end else if ( scroll_state == 18) begin
            if ( layer_idx == 0 ) begin
                if ( max_count < hc ) begin // debug info
                    max_count <= hc;
                end
                scroll_state <= 0;
            end else begin
                first_layer <= 0;
                layer_idx <= layer_idx - 1;
                scroll_state <= 2;
            end
        end

/// SPRITES

        // start drawing sprites
        if ( sprite_state == 0 && vc == 9'hf0 ) begin
            sprite_state <= 1;
            sprite_type <= 2'h0;
            sprite_control_latch <= sprite_control;
        end else if ( sprite_state == 1) begin
            framebuf_w    <= 0;
            sprite_state  <= 3;
        end else if ( sprite_state == 3) begin
            // are sprites disabled?
            if ( layer_enable[3] == 0 ) begin
                // abort
                sprite_type <= 3;
                sprite_idx <= 8'hff;
                sprite_state <= 30;
            end else begin
                sprite_idx <= 8'h00;
                sprite_state <= 4;
            end
        end else if ( sprite_state == 4) begin 
            sprite_obj_addr <= { sprite_type, sprite_idx, 2'b0 }; // setup sprite ram pointer read @ 6
            sprite_state <= 5;
        end else if ( sprite_state == 5) begin
            sprite_obj_addr <= sprite_obj_addr + 1; // setup read x ofset @ 7
            // object addr valid
            sprite_state <= 6;
        end else if ( sprite_state == 6) begin
            // object data valid
            sprite_ram_addr <= { 1'b1, sprite_obj_dout[10:0], 3'b100 };  // setup attr read.  blocks of 8 words.  first 4 words unused

            sprite_obj_addr <= sprite_obj_addr + 1; // setup read y ofset
            sprite_state <= 7;
        end else if ( sprite_state == 7) begin
            // attr addr valid
            sprite_ram_addr <= sprite_ram_addr + 1; // setup base x read
            
            sprite_obj_addr <= sprite_obj_addr + 1; // setup read tile num ofset
            
            // x ofset valid
            sprite_ofs_x <= sprite_obj_dout[8:0];

            sprite_state <= 8;
        end else if ( sprite_state == 8) begin
            // x read addr valid
            // attr data valid
            sprite_flip_y <= sprite_ram_dout[7];
            sprite_flip_x <= sprite_ram_dout[6];
            sprite_priority <= sprite_ram_dout[4];
            sprite_colour <= sprite_ram_dout[3:0] ; // bit 3 used for priority splitting
            sprite_ord    <= sprite_ram_dout[11:8];
            sprite_ord_en <= sprite_ram_dout[12];
// s32 mosaic = (attr & 0x0f00)>>8;
// s32 mossol = (attr & 0x1000)>>8;

            // y ofset valid
            sprite_ofs_y <= sprite_obj_dout[8:0];
            sprite_ram_addr <= sprite_ram_addr + 1; // setup base y read
            sprite_state <= 9;
        end else if ( sprite_state == 9) begin
            if ( sprite_type != {sprite_flip_y,sprite_flip_x} ) begin
                // off screen or flip orientation doesn't match current type
                // skip
                sprite_state <= 30;
            end else begin
                // x read data valid
                sprite_base_x <= sprite_ram_dout[8:0];
                sprite_ram_addr <= sprite_ram_addr + 1; // setup base number read
                sprite_ofs_num <= sprite_obj_dout[11:0];
                sprite_state <= 10;
            end
        end else if ( sprite_state == 10) begin
            sprite_base_y <= sprite_ram_dout[8:0];
            sprite_state <= 11;
        end else if ( sprite_state == 11) begin
            spr_y <= 0;
            spr_x <= 0;
            sprite_num <= sprite_ram_dout[11:0] + sprite_ofs_num; // add sprite num base to num offset
            sprite_state <= 12;
        end else if ( sprite_state == 12) begin
            // time to read sprite bitmap rom 
            sprite_rom_addr <= { sprite_num, spr_y[3:0] };

            sprite_rom_cs <= 1;
            sprite_state <= 13;
        end else if ( sprite_state == 13) begin
            if ( sprite_rom_valid == 1 ) begin
                // bitmap data valid.  deassert read
                sprite_rom_cs <= 0;
                sprite_pix_data <= sprite_rom_dout;
                sprite_state <= 14;
            end
        end else if ( sprite_state == 14) begin
            framebuf_addr <= { sprite_total_y[7:0], sprite_total_x[7:0] };
            framebuf_din  <= { sprite_control_latch[8], sprite_priority, sprite_colour, sprite_pen }; // sprite_control[8] = enable colour based priority
            if ( sprite_total_y < 240 && sprite_total_x < 256 && sprite_pen != 15 ) begin
                // only write if in viewable area and not transparent
                framebuf_w <= 1;
            end else begin
                framebuf_w <= 0;
            end
            if ( spr_x < 15 ) begin
                spr_x <= spr_x + 1;
            end else begin
                sprite_state <= 15;
            end
        end else if ( sprite_state == 15) begin
            framebuf_w <= 0;
            spr_x <= 0;
            if ( spr_y < 15 ) begin
                spr_y <= spr_y + 1;
                sprite_state <= 12; // read next line
            end else begin
                sprite_state <= 30; // done sprite
            end
            // sprite_state <= 30;
        end else if ( sprite_state == 30) begin
            if ( sprite_type < 3 ) begin
                sprite_type <= sprite_type + 1;
                sprite_state <= 4;
            end else begin
                if ( sprite_idx < 255 ) begin
                    sprite_idx <= sprite_idx + 1;
                    sprite_type <= 0;
                    sprite_state <= 4; // next sprite.  should be next type but just do not flipped for now
                end else begin
                    if ( vbl == 0 ) begin
                        sprite_state <= 0; // done for now.
                    end
                end
            end
        end
    end
end

wire  [4:0] flipped_x = { 4 {sprite_flip_x} } ^ spr_x;
wire  [4:0] flipped_y = { 4 {sprite_flip_y} } ^ spr_y;

wire  [8:0] sprite_total_x = sprite_base_x + sprite_ofs_x + ( sprite_ord_en ? ( flipped_x | sprite_ord ) : ( flipped_x & ~sprite_ord ) );
wire  [8:0] sprite_total_y = sprite_base_y + sprite_ofs_y + ( sprite_ord_en ? ( flipped_y | sprite_ord ) : ( flipped_y & ~sprite_ord ) );

reg   [4:0] sprite_state;

reg  [63:0] sprite_pix_data;
wire  [3:0] sprite_pen = sprite_pix_data[ {~spr_x[3:0] , 2'b11} -: 4 ] ; // [63:60]...[3:0]


reg   [1:0] sprite_type;
reg   [7:0] sprite_idx;
reg         sprite_priority;
reg   [3:0] sprite_colour;
reg   [9:0] sprite_base_x;
reg   [9:0] sprite_base_y;
//reg  [11:0] sprite_base_num;
reg  [11:0] sprite_num;

reg   [8:0] sprite_ofs_x;
reg   [8:0] sprite_ofs_y;
reg  [11:0] sprite_ofs_num;

reg         sprite_flip_y;
reg         sprite_flip_x;

reg   [3:0] spr_y;
reg   [3:0] spr_x;

//reg   [3:0] pen;
//reg         pen_valid;

// wire [8:0] fb_vc = vc[7:0] - 1; //+ 8'h10;
wire [8:0] fb_vc = ( dip_flip == 0 ? ( vc[7:0] - 1 ) : ( 255 - vc[7:0] + 1 ) ) ; //+ 8'h10;

reg  [3:0] sprite_priority_hi;
reg  [3:0] sprite_priority_lo;

always @ (posedge clk_sys) begin

    if ( vc < 242 ) begin
        if ( clk6_count == 2 ) begin
            // line_buf_addr_r <= { vc[0], 1'b0, hc[7:0] };
            line_buf_addr_r <= { vc[0], 1'b0, ( dip_flip == 0 ) ? hc[7:0] : ( 8'hff - hc[7:0]) };
        end else if ( clk6_count == 3 ) begin
            // line_buf_addr_r valid
           //  framebuf_addr_r <= { fb_vc, hc[7:0]  };
            framebuf_addr_r <= { fb_vc, ( dip_flip == 0 ) ? hc[7:0] : ( 8'hff - hc[7:0])  };
        end else if ( clk6_count == 4 ) begin
            case (4'h3)
                layer_prom[3:0]   : sprite_priority_hi <= 4;
                layer_prom[7:4]   : sprite_priority_hi <= 3;
                layer_prom[11:8]  : sprite_priority_hi <= 2;
                layer_prom[15:12] : sprite_priority_hi <= 1;
                layer_prom[19:16] : sprite_priority_hi <= 0;
            endcase
            case (4'h4)
                layer_prom[3:0]   : sprite_priority_lo <= 4;
                layer_prom[7:4]   : sprite_priority_lo <= 3;
                layer_prom[11:8]  : sprite_priority_lo <= 2;
                layer_prom[15:12] : sprite_priority_lo <= 1;
                layer_prom[19:16] : sprite_priority_lo <= 0;
            endcase

        end else if ( clk6_count == 5 ) begin
                framebuf_dout <= framebuf_dout_r; // fix naming
                if ( sprite_control[4] == 0 || ( ~framebuf_dout_r[7:4] == sprite_control[3:0] && sprite_control[0] == 0 ) ) begin
                    framebuf_w_r <= 1;
                    framebuf_din_r <= 15;
                end
        end else if ( clk6_count == 6 ) begin
                framebuf_w_r <= 0;
        end else if ( clk6_count == 7 ) begin
            if ( 
                // layer enabled
                layer_enable[3] == 1 &&
                // not transparent
                framebuf_dout[3:0] != 15 &&
                // sprite layer > tile layer 
                // when split, bit [3] of the sprite colour controls hi/low priority
                ( ( sprite_control[8] == 0 || framebuf_dout[7] == 0 ) ? sprite_priority_hi : sprite_priority_lo ) > ( 3'h4 - line_buf_dout[12:10] )
               ) begin
                    // framebuf_dout[7] priority when split
                if ( sprite_control[8] == 0 ) begin
                    palette_addr_r <= { 2'b11, framebuf_dout[7:0] };
                end else begin
                    palette_addr_r <= { 3'b110, framebuf_dout[6:0] };
                end
            end else begin
                palette_addr_r <= line_buf_dout[9:0];
            end
        end else if ( clk6_count == 9 ) begin
            if ( line_buf_dout[15] == 1 && framebuf_dout[3:0] == 4'hf ) begin
                rgb <= 0;
            end else begin
                //palette_device::RRRRGGGGBBBBRGBx
                rgb <= { palette_dout[15:12], palette_dout[3], 3'b0, palette_dout[11:8], palette_dout[2], 3'b0, palette_dout[7:4], palette_dout[1], 3'b0 };
            end
        end
    end
end


reg         framebuf_w;
reg         framebuf_w_r;
reg  [15:0] framebuf_addr;
reg  [15:0] framebuf_addr_r;
reg  [11:0] framebuf_din;
reg  [11:0] framebuf_din_r;
reg  [11:0] framebuf_dout;
wire [11:0] framebuf_dout_r;

// sprite frame buffer 256x256
dual_port_ram #(.LEN(65536), .DATA_WIDTH(12)) framebuf_ram
(
    .clock_a( clk_sys ),
    .address_a( framebuf_addr ),
    .wren_a( framebuf_w ),
    .data_a( framebuf_din ),
    .q_a(  ),

    .clock_b( clk_sys ),
    .address_b( framebuf_addr_r ),
    .data_b( framebuf_din_r ),
    .wren_b( framebuf_w_r ),
    .q_b( framebuf_dout_r )
);


wire [15:0] m68kp_ram_dout;

// scroll control registers
reg  [15:0] m68kp_scr0_reg_x;
reg  [15:0] m68kp_scr0_reg_y;
reg  [15:0] m68kp_scr0_reg_mode;

reg  [15:0] m68kp_scr1_reg_x;
reg  [15:0] m68kp_scr1_reg_y;
reg  [15:0] m68kp_scr1_reg_mode;

reg  [15:0] m68kp_scr2_reg_x;
reg  [15:0] m68kp_scr2_reg_y;
reg  [15:0] m68kp_scr2_reg_mode;

wire m68kp_scr0_reg = ( m68kp_a[2:1] == 0 ) ? m68kp_scr0_reg_x : ( m68kp_a[2:1] == 1 ) ? m68kp_scr0_reg_y : m68kp_scr0_reg_mode;
wire m68kp_scr1_reg = ( m68kp_a[2:1] == 0 ) ? m68kp_scr1_reg_x : ( m68kp_a[2:1] == 1 ) ? m68kp_scr1_reg_y : m68kp_scr1_reg_mode;
wire m68kp_scr2_reg = ( m68kp_a[2:1] == 0 ) ? m68kp_scr2_reg_x : ( m68kp_a[2:1] == 1 ) ? m68kp_scr2_reg_y : m68kp_scr2_reg_mode;

reg  [14:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout;

// todo: byte writes should mirror to both bytes
dual_port_ram #(.LEN(32768)) m68kp_ram_h
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[15:1] ),
    .wren_a( !m68kp_rw & m68kp_ram_cs & !m68kp_uds_n ),
    .data_a( m68kp_dout[15:8] ),
    .q_a( m68kp_ram_dout[15:8] ),

    .clock_b( clk_sys ),
    .address_b( sprite_ram_addr ),
    .wren_b( 0 ),
    .data_b( ),
    .q_b( sprite_ram_dout[15:8] )
);

dual_port_ram #(.LEN(32768)) m68kp_ram_l
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[15:1] ),
    .wren_a( !m68kp_rw & m68kp_ram_cs & !m68kp_lds_n ),
    .data_a( m68kp_dout[7:0] ),
    .q_a( m68kp_ram_dout[7:0] ),

    .clock_b( clk_sys ),
    .address_b( sprite_ram_addr ),
    .wren_b ( 0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
);


assign m68ks_rom_valid = 1;

// needs to be 65536*2 words long for some games
dual_port_ram #(.LEN(65536), .DATA_WIDTH(16)) m68ks_rom
(
    .clock_a( clk_sys ),
    .address_a( sound_rom_addr ),
    .wren_a( sound_rom_w ),
    .data_a( sound_rom_din ),
    .q_a( ),

    .clock_b( clk_cpu_s ),
    .address_b( m68ks_a[16:1] ),
    .wren_b( 0 ),
    .data_b( ),
    .q_b( m68ks_rom_dout )
);

wire [15:0] m68ks_ram_dout;

dual_port_ram #(.LEN(32768)) m68ks_ram_h
(
    .clock_a( clk_cpu_s ),
    .address_a( m68ks_a[15:1] ),
    .wren_a( !m68ks_rw & m68ks_ram_cs & !m68ks_uds_n ),
    .data_a( m68ks_dout[15:8] ),
    .q_a( m68ks_ram_dout[15:8] )

//    .clock_b( ),
//    .address_b( ),
//    .wren_b( ),
//    .data_b( ),
//    .q_b( )
);

dual_port_ram #(.LEN(32768)) m68ks_ram_l
(
    .clock_a( clk_cpu_s ),
    .address_a( m68ks_a[15:1] ),
    .wren_a( !m68ks_rw & m68ks_ram_cs & !m68ks_lds_n ),
    .data_a( m68ks_dout[7:0] ),
    .q_a( m68ks_ram_dout[7:0] )

//    .clock_b( ),
//    .address_b( ),
//    .wren_b ( ),
//    .data_b ( ),
//    .q_b( )
);

wire [15:0] sprite_dout;

reg  [11:0] sprite_obj_addr;
wire [15:0] sprite_obj_dout;

dual_port_ram #(.LEN(4096)) m68kp_spr_h
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[12:1] ),
    .wren_a( !m68kp_rw & m68kp_spr_cs & !m68kp_uds_n ),
    .data_a( m68kp_dout[15:8] ),
    .q_a( sprite_dout[15:8] ),

    .clock_b( clk_sys ),
    .address_b( sprite_obj_addr ),
    .wren_b( 0 ),
    .data_b( ),
    .q_b( sprite_obj_dout[15:8] )
);

dual_port_ram #(.LEN(4096)) m68kp_spr_l
(
    .clock_a ( clk_cpu_p ),
    .address_a ( m68kp_a[12:1] ),
    .wren_a ( !m68kp_rw & m68kp_spr_cs & !m68kp_lds_n ),
    .data_a ( m68kp_dout[7:0] ),
    .q_a ( sprite_dout[7:0] ),

    .clock_b( clk_sys ),
    .address_b( sprite_obj_addr ),
    .wren_b( 0 ),
    .data_b( ),
    .q_b( sprite_obj_dout[7:0] )
);

reg  [12:0] scroll0_addr_r;
wire [15:0] scroll0_dout;
wire [15:0] m68kp_scroll0_dout;

dual_port_ram #(.LEN(8192), .DATA_WIDTH(16)) scroll0_ram
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[13:1] ),
    .wren_a( !m68kp_rw & m68kp_scr0_cs ),
    .data_a( m68kp_dout ),
    .q_a( m68kp_scroll0_dout ),

    .clock_b( clk_sys ),
    .address_b( scroll0_addr_r ),
    .wren_b( 0 ),
    .q_b( scroll0_dout )
);

reg  [12:0] scroll1_addr_r;
wire [15:0] scroll1_dout;
wire [15:0] m68kp_scroll1_dout;

dual_port_ram #(.LEN(8192), .DATA_WIDTH(16)) scroll1_ram
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[13:1] ),
    .wren_a( !m68kp_rw & m68kp_scr1_cs ),
    .data_a( m68kp_dout ),
    .q_a( m68kp_scroll1_dout ),

    .clock_b( clk_sys ),
    .address_b( scroll1_addr_r ),
    .wren_b( 0 ),
    .q_b( scroll1_dout )
);

reg  [12:0] scroll2_addr_r;
wire [15:0] scroll2_dout;
wire [15:0] m68kp_scroll2_dout;

dual_port_ram #(.LEN(8192), .DATA_WIDTH(16)) scroll2_ram
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[13:1] ),
    .wren_a( !m68kp_rw & m68kp_scr2_cs ),
    .data_a( m68kp_dout ),
    .q_a( m68kp_scroll2_dout ),

    .clock_b( clk_sys ),
    .address_b( scroll2_addr_r ),
    .wren_b( 0 ),
    .q_b( scroll2_dout )
);

reg  [9:0]  palette_addr_r;
wire [15:0] palette_dout;
wire [15:0] m68kp_palette_dout;

dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) palette_ram
(
    .clock_a( clk_cpu_p ),
    .address_a( m68kp_a[10:1] ),
    .wren_a( !m68kp_rw & m68kp_pal_cs ),
    .data_a( m68kp_dout ),
    .q_a( m68kp_palette_dout ),

    .clock_b( clk_sys ),
    .address_b( palette_addr_r ),
    .wren_b( 0 ),
    .q_b( palette_dout )
);

assign ioctl_wait = download_wait;

reg         m68ks_rom_cs;
wire [15:0] m68ks_rom_dout;
wire        m68ks_rom_valid;

reg         m68kp_rom_cs;
wire [15:0] m68kp_rom_dout;
wire        m68kp_rom_valid;

reg         scroll0_rom_cs;
reg  [15:0] scroll0_rom_addr;
wire [63:0] scroll0_rom_dout;
wire        scroll0_rom_valid;

reg         scroll1_rom_cs;
reg  [15:0] scroll1_rom_addr;
wire [63:0] scroll1_rom_dout;
wire        scroll1_rom_valid;

reg         scroll2_rom_cs;
reg  [15:0] scroll2_rom_addr;
wire [63:0] scroll2_rom_dout;
wire        scroll2_rom_valid;

reg         sprite_rom_cs;
reg  [15:0] sprite_rom_addr;
wire [63:0] sprite_rom_dout;
wire        sprite_rom_valid;

reg  [17:0] oki0_rom_addr;
wire [ 7:0] oki0_rom_dout;
wire        oki0_rom_valid;

reg  [17:0] oki1_rom_addr;
wire [ 7:0] oki1_rom_dout;
wire        oki1_rom_valid;

// output from cache
wire        m68kp_cache_cs;
wire [22:0] m68kp_cache_addr;

// output from rom controller
wire [15:0] m68kp_cache_dout;
wire        m68kp_cache_valid;

// cpu rom decoding is done a it is read from sdram.  cache has decrypted value
wire [15:0] decoded_data =  cpu_decode( .i(m68kp_cache_addr), .d(m68kp_cache_dout) );

cache prog_cache
(
    .reset(reset),
    .clk(clk_sys),

    .cache_req(m68kp_rom_cs),
    .cache_addr(m68kp_a[18:1]),
    .cache_data(m68kp_rom_dout),
    .cache_valid(m68kp_rom_valid),

    .rom_req(m68kp_cache_cs),
    .rom_addr(m68kp_cache_addr),
    .rom_data(decoded_data),
    .rom_valid(m68kp_cache_valid)
);

rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
    .prog_rom_cs(m68kp_cache_cs),
    .prog_rom_oe(1),
    .prog_rom_addr(m68kp_cache_addr),
    .prog_rom_data(m68kp_cache_dout),
    .prog_rom_data_valid(m68kp_cache_valid),
    
//    .prog_rom_cs(m68kp_rom_cs),
//    .prog_rom_oe(1),
//    .prog_rom_addr(m68kp_a[23:1]),
//    .prog_rom_data(m68kp_rom_dout),
//    .prog_rom_data_valid(m68kp_rom_valid),
    
    // sound ROM interface
//    .sound_rom_cs(m68ks_rom_cs),
//    .sound_rom_oe(1),
//    .sound_rom_addr(m68ks_a[23:1]),
//    .sound_rom_data(m68ks_rom_dout),
//    .sound_rom_data_valid(m68ks_rom_valid),

    .scroll0_rom_cs(scroll0_rom_cs),
    .scroll0_rom_oe(1),
    .scroll0_rom_addr(scroll0_rom_addr),
    .scroll0_rom_data(scroll0_rom_dout),
    .scroll0_rom_data_valid(scroll0_rom_valid),

    .scroll1_rom_cs(scroll1_rom_cs),
    .scroll1_rom_oe(1),
    .scroll1_rom_addr(scroll1_rom_addr),
    .scroll1_rom_data(scroll1_rom_dout),
    .scroll1_rom_data_valid(scroll1_rom_valid),
    
    .scroll2_rom_cs(scroll2_rom_cs),
    .scroll2_rom_oe(1),
    .scroll2_rom_addr(scroll2_rom_addr),
    .scroll2_rom_data(scroll2_rom_dout),
    .scroll2_rom_data_valid(scroll2_rom_valid),

    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_dout),
    .sprite_rom_data_valid(sprite_rom_valid),

    .pcm1_rom_cs(oki0_rom_cs),
    .pcm1_rom_oe(1),
    .pcm1_rom_addr(oki0_rom_addr),
    .pcm1_rom_data(oki0_rom_dout),
    .pcm1_rom_data_valid(oki0_rom_valid),

    .pcm2_rom_cs(oki1_rom_cs),
    .pcm2_rom_oe(1),
    .pcm2_rom_addr(oki1_rom_addr),
    .pcm2_rom_data(oki1_rom_dout),
    .pcm2_rom_data_valid(oki1_rom_valid),

    // IOCTL interface
    .ioctl_addr(download_addr), // swizzled ioctl_addr
    .ioctl_data(download_data),
    .ioctl_index(download_index),
    .ioctl_wr(download_wr),
    .ioctl_download(download_en),
    .ioctl_wait(download_wait),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_done(sdram_done),
    .sdram_q(sdram_q)
  );

reg  [22:0] sdram_addr;
reg  [63:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire        sdram_done;
wire [63:0] sdram_q;

sdram #(.CLK_FREQ( (72.0)), .DATA_WIDTH(64), .BURST_LENGTH(4), .CAS_LATENCY(2) ) sdram
(
  .reset(~pll_locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  .done(sdram_done),

  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);

endmodule
