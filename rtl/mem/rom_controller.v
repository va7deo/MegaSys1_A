
`default_nettype none

module rom_controller 
(
    // reset
    input reset,

    // clock
    input clk,

    // program ROM interface
    input  prog_rom_cs,
    input  prog_rom_oe,
    input  [17:0] prog_rom_addr, // word address.
    output [15:0] prog_rom_data,
    output prog_rom_data_valid,
    
    // sound program ROM interface
    input  sound_rom_cs,
    input  sound_rom_oe,
    input  [16:0] sound_rom_addr, // word address.
    output [15:0] sound_rom_data,
    output sound_rom_data_valid,    
    
    // pcm samples #1 interface
    input  pcm1_rom_cs,
    input  pcm1_rom_oe,
    input  [19:0] pcm1_rom_addr,
    output [7:0] pcm1_rom_data,
    output pcm1_rom_data_valid,     

    // pcm samples #2 interface
    input  pcm2_rom_cs,
    input  pcm2_rom_oe,
    input  [18:0] pcm2_rom_addr,
    output [7:0] pcm2_rom_data,
    output pcm2_rom_data_valid,     

    // scroll0 ROM #1 interface
    input  scroll0_rom_cs,
    input  scroll0_rom_oe,
    input  [15:0] scroll0_rom_addr,
    output [63:0] scroll0_rom_data,
    output scroll0_rom_data_valid,    

    // scroll1 ROM #1 interface
    input  scroll1_rom_cs,
    input  scroll1_rom_oe,
    input  [15:0] scroll1_rom_addr,
    output [63:0] scroll1_rom_data,
    output scroll1_rom_data_valid,    

    // scroll2 ROM #1 interface
    input  scroll2_rom_cs,
    input  scroll2_rom_oe,
    input  [13:0] scroll2_rom_addr,
    output [63:0] scroll2_rom_data,
    output scroll2_rom_data_valid,   
   
    // sprite ROM #1 interface
    input  sprite_rom_cs,
    input  sprite_rom_oe,
    input  [16:0] sprite_rom_addr,
    output [63:0] sprite_rom_data,
    output sprite_rom_data_valid,    
    
    // IOCTL interface
    input  [24:0] ioctl_addr,
    input  [7:0] ioctl_data,
    input  [15:0] ioctl_index,
    input  ioctl_wr,
    input  ioctl_download,
    output reg ioctl_wait,

    // SDRAM interface
    output reg [22:0] sdram_addr,
    output reg [63:0] sdram_data,
    output reg sdram_we,
    output reg sdram_req,
    input  sdram_ack,
    input  sdram_valid,
    input  sdram_done,
    input  [63:0] sdram_q
  );

localparam NONE         = 0; 
localparam PROG_ROM     = 1;
localparam SOUND_ROM    = 2;
localparam SPRITE_ROM   = 3;
localparam SCROLL0_ROM  = 4;
localparam SCROLL1_ROM  = 5;
localparam SCROLL2_ROM  = 6;
localparam PCM1_ROM     = 7;
localparam PCM2_ROM     = 8;
  
// ROM wires
reg [3:0] rom;
reg [3:0] next_rom;
reg [3:0] pending_rom;

// ROM request wires
reg prog_rom_ctrl_req;
reg sound_rom_ctrl_req;
reg pcm1_rom_ctrl_req;
reg pcm2_rom_ctrl_req;
reg scroll0_rom_ctrl_req;
reg scroll1_rom_ctrl_req;
reg scroll2_rom_ctrl_req;
reg sprite_rom_ctrl_req;

// ROM acknowledge wires
reg prog_rom_ctrl_ack;
reg sound_rom_ctrl_ack;
reg pcm1_rom_ctrl_ack;
reg pcm2_rom_ctrl_ack;
reg scroll0_rom_ctrl_ack;
reg scroll1_rom_ctrl_ack;
reg scroll2_rom_ctrl_ack;
reg sprite_rom_ctrl_ack;

reg prog_rom_ctrl_hit;
reg sound_rom_ctrl_hit;
reg pcm1_rom_ctrl_hit;
reg pcm2_rom_ctrl_hit;
reg scroll0_rom_ctrl_hit;
reg scroll1_rom_ctrl_hit;
reg scroll2_rom_ctrl_hit;
reg sprite_rom_ctrl_hit;

// ROM valid wires
reg prog_rom_ctrl_valid;
reg sound_rom_ctrl_valid;
reg pcm1_rom_ctrl_valid;
reg pcm2_rom_ctrl_valid;
reg scroll0_rom_ctrl_valid;
reg scroll1_rom_ctrl_valid;
reg scroll2_rom_ctrl_valid;
reg sprite_rom_ctrl_valid;

// address mux wires
reg [22:0] prog_rom_ctrl_addr;
reg [22:0] sound_rom_ctrl_addr;
reg [22:0] pcm1_rom_ctrl_addr;
reg [22:0] pcm2_rom_ctrl_addr;
reg [22:0] scroll0_rom_ctrl_addr;
reg [22:0] scroll1_rom_ctrl_addr;
reg [22:0] scroll2_rom_ctrl_addr;
reg [22:0] sprite_rom_ctrl_addr;

// download wires
reg [22:0] download_addr;
reg [63:0] download_data;
reg download_req;

// control wires
reg ctrl_req;

// The SDRAM controller has a 64-bit interface, so we need to buffer the
// bytes received from the IOCTL interface in order to write 64-bit words to
// the SDRAM. 

//ioctl_wait
//download_buffer #(.SIZE(8) ) download_buffer
//(
//    .clk(clk),
//    .reset(~ioctl_download | ~sdram_we),
//    .din(ioctl_data),
//    .dout(download_data),
//    .we(ioctl_download & ioctl_wr),
//    .valid(download_req)
//);


reg download_write;
reg pending_write ;
reg pending_read ;
reg [2:0] download_state ;

// loads 64 bits from sdram then updates 8 bits of that and writes it back
// allows arbitrary byte ordering

always @ (posedge clk) begin
    if ( ioctl_index != 0 || ioctl_download == 0 ) begin
        download_write <= 0;
        ioctl_wait <= 0;
        download_req <= 0;
        download_state <= 0;
    end else begin
        if ( ioctl_wr == 1 && download_state == 0 ) begin
            // tell ioctl to wait and read sdram
            download_req <= 1;
            ioctl_wait <= 1;
            download_state <= 1;
        end if (download_state == 1 && sdram_valid == 1 ) begin
            // data should be available
            download_req <= 0;
            download_data  <= sdram_q;
            download_state <= 2;
        end else if ( download_state == 2 ) begin 
            // overwrite byte with new data
            download_data[ {~ioctl_addr[2:0], 3'b111} -: 8 ] <= ioctl_data ;
            download_req   <= 1;
            download_write <= 1;
            download_state <= 3;
        end else if ( download_state == 3 && sdram_done == 1 ) begin
            // write complete
            download_req <= 0;
            download_write <= 0;
            download_state <= 4;
        end else if ( download_state == 4 ) begin
            download_state <= 0;
            ioctl_wait <= 0;
        end
    end
end

// region       size    aw  b dw      ofs 
// --------------------------------------
// maincpu	    80000   19  1 16    00000
// audiocpu     40000   18  1 16    80000
// oki1        100000   20  0  8   100000
// oki2	        80000   19  0  8   200000
// scroll0	    80000   19  3 64   280000
// scroll1	    80000   19  3 64   300000
// scroll2	    20000   17  3 64   380000
// sprites	   100000   20  3 64   400000
// proms	      200    9  0  8   500000
// mcu	         2000   13  0  8

segment 
#(
    .ROM_ADDR_WIDTH(18),
    .ROM_DATA_WIDTH(16),
    .ROM_OFFSET(24'h000000)
) prog_rom_segment 
(
    .reset(reset),
    .clk(clk),
    .cs(prog_rom_cs & !ioctl_download),
    .oe(prog_rom_oe),
    .ctrl_addr(prog_rom_ctrl_addr),
    .ctrl_req(prog_rom_ctrl_req),
    .ctrl_ack(prog_rom_ctrl_ack),
    .ctrl_valid(prog_rom_ctrl_valid),
    .ctrl_hit(prog_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(prog_rom_addr),
    .rom_data(prog_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(17),
    .ROM_DATA_WIDTH(16),
    .ROM_OFFSET(24'h080000)
) sound_rom_segment 
(
    .reset(reset),
    .clk(clk),
    .cs(sound_rom_cs & !ioctl_download),
    .oe(sound_rom_oe),
    .ctrl_addr(sound_rom_ctrl_addr),
    .ctrl_req(sound_rom_ctrl_req),
    .ctrl_ack(sound_rom_ctrl_ack),
    .ctrl_valid(sound_rom_ctrl_valid),
    .ctrl_hit(sound_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(sound_rom_addr),
    .rom_data(sound_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(20),
    .ROM_DATA_WIDTH(8),
    .ROM_OFFSET(24'h100000)
) pcm1_rom_segment 
(
    .reset(reset),
    .clk(clk),
    .cs(pcm1_rom_cs & !ioctl_download),
    .oe(pcm1_rom_oe),
    .ctrl_addr(pcm1_rom_ctrl_addr),
    .ctrl_req(pcm1_rom_ctrl_req),
    .ctrl_ack(pcm1_rom_ctrl_ack),
    .ctrl_valid(pcm1_rom_ctrl_valid),
    .ctrl_hit(pcm1_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(pcm1_rom_addr),
    .rom_data(pcm1_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(19),
    .ROM_DATA_WIDTH(8),
    .ROM_OFFSET(24'h200000)
) pcm2_rom_segment 
(
    .reset(reset),
    .clk(clk),
    .cs(pcm2_rom_cs & !ioctl_download),
    .oe(pcm2_rom_oe),
    .ctrl_addr(pcm2_rom_ctrl_addr),
    .ctrl_req(pcm2_rom_ctrl_req),
    .ctrl_ack(pcm2_rom_ctrl_ack),
    .ctrl_valid(pcm2_rom_ctrl_valid),
    .ctrl_hit(pcm2_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(pcm2_rom_addr),
    .rom_data(pcm2_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(16),
    .ROM_DATA_WIDTH(64),
    .ROM_OFFSET(24'h280000)
) scroll0_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(scroll0_rom_cs & !ioctl_download),
    .oe(scroll0_rom_oe),
    .ctrl_addr(scroll0_rom_ctrl_addr),
    .ctrl_req(scroll0_rom_ctrl_req),
    .ctrl_ack(scroll0_rom_ctrl_ack),
    .ctrl_valid(scroll0_rom_ctrl_valid),
    .ctrl_hit(scroll0_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(scroll0_rom_addr),
    .rom_data(scroll0_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(16),
    .ROM_DATA_WIDTH(64),
    .ROM_OFFSET(24'h300000)
) scroll1_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(scroll1_rom_cs & !ioctl_download),
    .oe(scroll1_rom_oe),
    .ctrl_addr(scroll1_rom_ctrl_addr),
    .ctrl_req(scroll1_rom_ctrl_req),
    .ctrl_ack(scroll1_rom_ctrl_ack),
    .ctrl_valid(scroll1_rom_ctrl_valid),
    .ctrl_hit(scroll1_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(scroll1_rom_addr),
    .rom_data(scroll1_rom_data)
);

segment
#(
    .ROM_ADDR_WIDTH(16), // 0x40000 x 16 words - 4MB
    .ROM_DATA_WIDTH(64),
    .ROM_OFFSET(24'h380000)
) scroll2_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(scroll2_rom_cs & !ioctl_download),
    .oe(scroll2_rom_oe),
    .ctrl_addr(scroll2_rom_ctrl_addr),
    .ctrl_req(scroll2_rom_ctrl_req),
    .ctrl_ack(scroll2_rom_ctrl_ack),
    .ctrl_valid(scroll2_rom_ctrl_valid),
    .ctrl_hit(scroll2_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(scroll2_rom_addr),
    .rom_data(scroll2_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(17), // 0x40000 x 16 words - 4MB
    .ROM_DATA_WIDTH(64),
    .ROM_OFFSET(24'h400000)
) sprite_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(sprite_rom_cs & !ioctl_download),
    .oe(sprite_rom_oe),
    .ctrl_addr(sprite_rom_ctrl_addr),
    .ctrl_req(sprite_rom_ctrl_req),
    .ctrl_ack(sprite_rom_ctrl_ack),
    .ctrl_valid(sprite_rom_ctrl_valid),
    .ctrl_hit(sprite_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(sprite_rom_addr),
    .rom_data(sprite_rom_data)
);



// latch the next ROM
always @ (posedge clk, posedge reset) begin
    if ( reset == 1 ) begin
        rom <= NONE;
        pending_rom <= NONE;
    end else begin
        // default to not having any ROM selected
        rom <= NONE;

        // set the current ROM register when ROM data is not being downloaded
        if ( ioctl_download == 0 ) begin
            rom <= next_rom;
        end;

        // set the pending ROM register when a request is acknowledged (i.e.
        // a new request has been started)
        if ( sdram_ack == 1 ) begin
            pending_rom <= rom;
        end

        sdram_valid_reg <= sdram_valid;
    end
end

reg sdram_valid_reg;

   
// select cpu data input based on what is active
assign prog_rom_data_valid     = prog_rom_cs    & ( prog_rom_ctrl_hit    | (pending_rom == PROG_ROM    ? sdram_valid : 0) ) & ~reset;
assign sound_rom_data_valid    = sound_rom_cs   & ( sound_rom_ctrl_hit   | (pending_rom == SOUND_ROM   ? sdram_valid : 0) ) & ~reset;
assign sprite_rom_data_valid   = sprite_rom_cs  & ( sprite_rom_ctrl_hit  | (pending_rom == SPRITE_ROM  ? sdram_valid : 0) ) & ~reset;
assign scroll0_rom_data_valid  = scroll0_rom_cs & ( scroll0_rom_ctrl_hit | (pending_rom == SCROLL0_ROM ? sdram_valid : 0) ) & ~reset;
assign scroll1_rom_data_valid  = scroll1_rom_cs & ( scroll1_rom_ctrl_hit | (pending_rom == SCROLL1_ROM ? sdram_valid : 0) ) & ~reset;
assign scroll2_rom_data_valid  = scroll2_rom_cs & ( scroll2_rom_ctrl_hit | (pending_rom == SCROLL2_ROM ? sdram_valid : 0) ) & ~reset;
assign pcm1_rom_data_valid     = pcm1_rom_cs    & ( pcm1_rom_ctrl_hit    | (pending_rom == PCM1_ROM    ? sdram_valid : 0) ) & ~reset;
assign pcm2_rom_data_valid     = pcm2_rom_cs    & ( pcm2_rom_ctrl_hit    | (pending_rom == PCM2_ROM    ? sdram_valid : 0) ) & ~reset;

always @ (*) begin

    // mux the next ROM in priority order

    next_rom <= NONE;  // default
    case (1)
        prog_rom_ctrl_req:      next_rom <= PROG_ROM;
        sound_rom_ctrl_req:     next_rom <= SOUND_ROM;
        scroll0_rom_ctrl_req:   next_rom <= SCROLL0_ROM;
        scroll1_rom_ctrl_req:   next_rom <= SCROLL1_ROM;
        scroll2_rom_ctrl_req:   next_rom <= SCROLL2_ROM;
        sprite_rom_ctrl_req:    next_rom <= SPRITE_ROM;
        pcm1_rom_ctrl_req:      next_rom <= PCM1_ROM;
        pcm2_rom_ctrl_req:      next_rom <= PCM2_ROM;
    endcase

    // route SDRAM acknowledge wire to the current ROM
    prog_rom_ctrl_ack <= 0;
    sound_rom_ctrl_ack <= 0;
    sprite_rom_ctrl_ack <= 0;
    scroll0_rom_ctrl_ack <= 0;
    scroll1_rom_ctrl_ack <= 0;
    scroll2_rom_ctrl_ack <= 0;
    pcm1_rom_ctrl_ack <= 0;
    pcm2_rom_ctrl_ack <= 0;

    case (rom)
        PROG_ROM:       prog_rom_ctrl_ack    <= sdram_ack;
        SOUND_ROM:      sound_rom_ctrl_ack   <= sdram_ack;
        SCROLL0_ROM:    scroll0_rom_ctrl_ack <= sdram_ack;
        SCROLL1_ROM:    scroll1_rom_ctrl_ack <= sdram_ack;
        SCROLL2_ROM:    scroll2_rom_ctrl_ack <= sdram_ack;
        SPRITE_ROM:     sprite_rom_ctrl_ack  <= sdram_ack;
        PCM1_ROM:       pcm1_rom_ctrl_ack    <= sdram_ack;
        PCM2_ROM:       pcm2_rom_ctrl_ack    <= sdram_ack;
    endcase

    
    // route SDRAM valid wire to the pending ROM
    prog_rom_ctrl_valid   <= 0;
    sound_rom_ctrl_valid  <= 0;
    sprite_rom_ctrl_valid <= 0;
    scroll0_rom_ctrl_valid <= 0;
    scroll1_rom_ctrl_valid <= 0;
    scroll2_rom_ctrl_valid <= 0;
    pcm1_rom_ctrl_valid <= 0;
    pcm2_rom_ctrl_valid <= 0;

    case (pending_rom)
        PROG_ROM:       prog_rom_ctrl_valid    <= sdram_valid;
        SOUND_ROM:      sound_rom_ctrl_valid   <= sdram_valid;
        SCROLL0_ROM:    scroll0_rom_ctrl_valid <= sdram_valid;
        SCROLL1_ROM:    scroll1_rom_ctrl_valid <= sdram_valid;
        SCROLL2_ROM:    scroll2_rom_ctrl_valid <= sdram_valid;
        SPRITE_ROM:     sprite_rom_ctrl_valid  <= sdram_valid;
        PCM1_ROM:       pcm1_rom_ctrl_valid    <= sdram_valid;
        PCM2_ROM:       pcm2_rom_ctrl_valid    <= sdram_valid;
    endcase


    // mux ROM request
    ctrl_req <= | { prog_rom_ctrl_req, sound_rom_ctrl_req, sprite_rom_ctrl_req, scroll0_rom_ctrl_req, 
                    scroll1_rom_ctrl_req, scroll2_rom_ctrl_req, pcm1_rom_ctrl_req, pcm2_rom_ctrl_req } ;

     // mux SDRAM address in priority order
     sdram_addr <= 0;
     case (1)
        ioctl_download:         sdram_addr <= download_addr;
        prog_rom_ctrl_req:      sdram_addr <= prog_rom_ctrl_addr;
        sound_rom_ctrl_req:     sdram_addr <= sound_rom_ctrl_addr;
        scroll0_rom_ctrl_req:   sdram_addr <= scroll0_rom_ctrl_addr;
        scroll1_rom_ctrl_req:   sdram_addr <= scroll1_rom_ctrl_addr;
        scroll2_rom_ctrl_req:   sdram_addr <= scroll2_rom_ctrl_addr;
        sprite_rom_ctrl_req:    sdram_addr <= sprite_rom_ctrl_addr;
        pcm1_rom_ctrl_req:      sdram_addr <= pcm1_rom_ctrl_addr;
        pcm2_rom_ctrl_req:      sdram_addr <= pcm2_rom_ctrl_addr;
     endcase 
     
    // set SDRAM data input
    sdram_data <= download_data;

    // set SDRAM request
    sdram_req <= (ioctl_download & download_req) | (!ioctl_download & ctrl_req) ;

    // enable writing to the SDRAM when downloading ROM data
    //sdram_we <= ioctl_download & ( ioctl_index == 0 );
    sdram_we <= download_write ;

    // we need to divide the address by eight, because we're converting from
    // a 8-bit IOCTL address to a 64-bit SDRAM address
    
    download_addr <= ioctl_addr[24:3];
end

endmodule 
