//

module chip_select
(
    input        clk,
    input  [4:0] pcb,

    input [23:0] m68kp_a,
    input        m68kp_as_n,
    input        m68kp_rw,

    input [23:0] m68ks_a,
    input        m68ks_as_n,
    input        m68ks_rw,

    // M68K selects
    output reg m68kp_rom_cs,
    output reg m68kp_ram_cs,

    output reg m68kp_p1_cs,
    output reg m68kp_p2_cs,
    output reg m68kp_dsw_cs,
    output reg m68kp_sys_cs,

    output reg m68kp_pal_cs,
    output reg m68kp_layer_cs,

    output reg m68kp_scr0_reg_cs,
    output reg m68kp_scr1_reg_cs,
    output reg m68kp_scr2_reg_cs,

    output reg m68kp_scr0_cs,
    output reg m68kp_scr1_cs,
    output reg m68kp_scr2_cs,

    output reg m68kp_spr_cs,
    output reg m68kp_spr_ctrl_cs,
    output reg m68kp_scr_ctrl_cs,

    output reg m68kp_latch0_cs,
    output reg m68kp_latch1_cs,

    output reg m68ks_rom_cs,
    output reg m68ks_latch0_cs,
    output reg m68ks_latch1_cs,
    output reg m68ks_ym2151_cs,
    output reg m68ks_oki0_cs,
    output reg m68ks_oki1_cs,
    output reg m68ks_ram_cs
);

// [19:0] only 20 bits are decoded

function m68kp_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68kp_cs = ( m68kp_a[19:0] >= start_address[19:0] && m68kp_a[19:0] <= end_address[19:0]); // & !m68kp_as_n;
end
endfunction

function m68ks_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68ks_cs = ( m68ks_a[19:0] >= start_address[19:0] && m68ks_a[19:0] <= end_address[19:0]); // & !m68ks_as_n;
end
endfunction

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

always @ (*) begin
    // Memory mapping based on PCB type
    case (pcb)
        default: begin
            // main cpu
            m68kp_rom_cs    <= m68kp_cs( 24'h000000, 24'h07ffff );

            m68kp_sys_cs    <= m68kp_cs( 24'h080000, 24'h080001 ) & m68kp_rw;
            m68kp_p1_cs     <= m68kp_cs( 24'h080002, 24'h080003 ) & m68kp_rw;
            m68kp_p2_cs     <= m68kp_cs( 24'h080004, 24'h080005 ) & m68kp_rw;
            m68kp_dsw_cs    <= m68kp_cs( 24'h080006, 24'h080006 ) & m68kp_rw;

            m68kp_layer_cs  <= m68kp_cs( 24'h084000, 24'h084001 );
            m68kp_latch1_cs <= m68kp_cs( 24'h080008, 24'h080009 );
            m68kp_latch0_cs <= m68kp_cs( 24'h084308, 24'h084309 );

            m68kp_pal_cs    <= m68kp_cs( 24'h088000, 24'h0887ff );

            // soldam sprite ram 0x8c000, 0x8cfff
            m68kp_spr_cs      <= m68kp_cs( 24'h08e000, 24'h08ffff ) | m68kp_cs( 24'h08c000, 24'h08cfff ); // object ram
            m68kp_spr_ctrl_cs <= m68kp_cs( 24'h084100, 24'h084101 );
            m68kp_scr_ctrl_cs <= m68kp_cs( 24'h084300, 24'h084301 );

            m68kp_scr0_reg_cs   <= m68kp_cs( 24'h084200, 24'h084205 );
            m68kp_scr1_reg_cs   <= m68kp_cs( 24'h084208, 24'h08420d );
            m68kp_scr2_reg_cs   <= m68kp_cs( 24'h084008, 24'h08400d );

            m68kp_scr0_cs   <= m68kp_cs( 24'h090000, 24'h093fff );
            m68kp_scr1_cs   <= m68kp_cs( 24'h094000, 24'h097fff );
            m68kp_scr2_cs   <= m68kp_cs( 24'h098000, 24'h09bfff );

            m68kp_ram_cs    <= m68kp_cs( 24'h0f0000, 24'h0fffff );

            // sound
            m68ks_rom_cs    <= m68ks_cs( 24'h000000, 24'h01ffff );
            m68ks_latch0_cs <= m68ks_cs( 24'h040000, 24'h040001 );
            m68ks_latch1_cs <= m68ks_cs( 24'h060000, 24'h060001 );
            m68ks_ym2151_cs <= m68ks_cs( 24'h080000, 24'h080003 );

            m68ks_oki0_cs <= m68ks_cs( 24'h0a0000, 24'h0a0003 );
            m68ks_oki1_cs <= m68ks_cs( 24'h0c0000, 24'h0c0003 );

            m68ks_ram_cs    <= m68ks_cs( 24'h0e0000, 24'h0fffff ); // 64k of ram mirrored to 128k
        end
    endcase
end

endmodule
