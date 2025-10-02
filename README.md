
# Jaleco Mega System 1 A FPGA Implementation

FPGA compatible core of Jaleco's Mega System 1 A (P-47 based) arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Erin Olafson**] with assistance from [**atrac17**](https://github.com/atrac17). Verified against a authentic P-47: The Freedom Fighter PCB purchased by [**atrac17**](https://github.com/atrac17).

The intent is for this core to be a 1:1 playable implementation of the Mega System 1 A arcade hardware. Currently in **beta state**, this core is in active development. Additional Mega System 1 arcade titles will be in separate repositories (Mega System 1 Rev Z/B/C).

<br>
<p align="center">
<img width="" height="" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/1fa22090-2ecc-451f-b977-a33e8ac41260">
</p>

## Supported Titles (Type-A)

| Title                                                    | PCB<br>Number        | Encrypted<br>Program | MCU | Status                  | Released     |
|----------------------------------------------------------|----------------------|----------------------|-----|-------------------------|--------------|
| [**P-47: The Freedom Fighter**](FILLME)                  | MB8844<br><br>MB8843 | N/A                  | N/A | **Implemented**         | **20230701** |
| [**Kick Off - Jaleco Cup**](FILLME)                      | MB8844               | N/A                  | N/A | **Implemented / W.I.P** | No           |
| [**Shingen Samurai-Fighter / Takeda Shingen**](FILLME)   | MB8844               | Yes                  | N/A | **Implemented / W.I.P** | No           |
| [**Ninja Kazan / Iga Ninjyutsuden**](FILLME)             | MB8845               | Yes                  | Yes | **Implemented**         | **20230923** |
| [**The Astyanax / The Lord of King**](FILLME)            | MB8844<br><br>MB8845 | Yes                  | Yes | **Implemented**         | **20230701** |
| [**Hachoo!**](FILLME)                                    | MB8845               | Yes                  | Yes | **Implemented**         | **20240101** |
| [**Jitsuryoku!! Pro Yakyuu**](FILLME)                    | MBMO2A               | Yes                  | Yes | **Implemented**         | **20240106** |
| [**Plus Alpha**](FILLME)                                 | MB8845               | Yes                  | Yes | **Implemented**         | **20240106** |
| [**Saint Dragon**](FILLME)                               | MB8845               | Yes                  | Yes | **Implemented**         | **20230715** |
| [**Rod-Land**](https://en.wikipedia.org/wiki/Rod_Land)   | MBMO2A<br><br>MB8845 | Yes                  | N/A | **Implemented**         | **20230513** |
| [**Phantasm**](FILLME)                                   | MB8845               | Yes                  | N/A | **Implemented**         | **20230708** |
| [**E.D.F: Earth Defense Force (Prototpe)**](FILLME)      | W.I.P                | Yes                  | N/A | **Implemented**         | **20240101** |
| [**In Your Face (Prototpe)**](FILLME)                    | W.I.P                | Yes                  | N/A | **Implemented**         | **20240101** |
| [**Soldam**](FILLME)                                     | W.I.P                | Yes                  | N/A | **Implemented**         | **20230519** |

## External Modules

| Module                                                                                | Function                                                               | Author                                         |
|---------------------------------------------------------------------------------------|------------------------------------------------------------------------|------------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                            | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                     |
| [**fx68k**](https://github.com/ijor/fx68k)                                            | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                     |
| [**jt51**](https://github.com/jotego/jt51)                                            | [**Yamaha YM2151**](https://en.wikipedia.org/wiki/Yamaha_YM2151)       | Jose Tejada                                    |
| [**jt6295**](https://github.com/jotego/jt6295)                                        | [**OKI MSM6295**](https://dtsheet.com/doc/957023/oki-m6295)            | Jose Tejada                                    |
| [**jt6295**](https://github.com/jotego/jt6295)                                        | [**OKI MSM6295**](https://dtsheet.com/doc/957023/oki-m6295)            | Jose Tejada                                    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)                        | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone                                    |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem)    | SDRAM Controller / Rom Downloader                                      | Josh Bassett, modified by Erin Olafson       |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)                  | MiSTer Framework Template                                              | sorgelig, modified by Erin Olafson / atrac17 |

# Known Issues / Tasks

- ~~OKI playback; correct samples (ROM board dependent)~~  **[Issue]**  

- Mosaic OBJ effects verify against PCB (P-47 JALECO logo)  **[Task]**
- OBJ Scroll effects verify against PCB (P-47 trail effect)  **[Task]**
- ~~Screen flip implementation~~  **[Task]**  
- ~~Verify H-FLIP / V-FLIP for screen flip against PCB~~  **[Task]**
- ~~Program CPU overclock toggle~~  **[Task]**  
- ~~OPM / ADPCM audio mix toggles~~  **[Task]**  
- ~~Verify analog timings from MB8842 mother board~~  **[Task]**  
- ~~Measure HBL, VBL, H-SYNC, and V-SYNC timings from MB8842 mother board~~  **[Task]**  
- ~~64-Bit SDRAM controller access for sprites  **[Task]**~~  

# PCB Check List

## Clock Information

| H-Sync    | V-Sync    | Source    | PCB<br>Number |
|-----------|-----------|-----------|---------------|
| 15.625kHz | 56.205035 | DSLogic+  | **MB8842**    |

## Crystal Oscillators

| Freq (MHz) | Use                                               | PCB<br>Number                     |
|------------|---------------------------------------------------|-----------------------------------|
| 4.000 MHz  | OKI MSM6295 / MCU CLKS (4 MHz)                    | **ROM Board<br>(See PCB Number)** |
| 7.000 MHz  | M68000 AUDIO CLOCK (7MHz)<br>YM2151 CLK (3.5 MHz) | **MB8842**                        |
| 12.000 MHz | M68000 CPU CLK (6 MHz)<br>Pixel CLK (6 MHz)       | **MB8842**                        |

**Pixel clock:** 6.00 MHz

**Estimated geometry:**

    384 pixels/line  
  
    278 lines/frame  

## Main Components

| Chip                                                                   | Use         | PCB Number                        |
|------------------------------------------------------------------------|-------------|-----------------------------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU    | **MB8842**                        |
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Audio CPU   | **MB8842**                        |
| [**Yamaha YM2151**](https://en.wikipedia.org/wiki/Yamaha_YM2151)       | OPM Sound   | **MB8842**                        |
| [**OKI MSM6295**](https://dtsheet.com/doc/957023/oki-m6295)            | ADPCM Sound | **ROM Board<br>(See PCB Number)** |
| [**OKI MSM6295**](https://dtsheet.com/doc/957023/oki-m6295)            | ADPCM Sound | **ROM Board<br>(See PCB Number)** |

### Custom Components

| Chip                            | Function                 |
| --------------------------------|--------------------------|
| **NEC D65005GB200**             | Custom Gate-Array / OBJ  |
| **NEC D65005GB249**             | Custom Gate-Array / SYNC |
| **NEC D65012GF303**             | Custom Gate-Array / VCTR |
| **NEC D65012GF307**             | Custom Gate-Array / SCPT | <br>

# Core Features

### Refresh Rate Compatibility Option

- Video timings can be modified if you experience sync issues with CRT or modern displays; this will alter gameplay from it's original state.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 15.63kHz / 56.2Hz | MB8842               | 384    | 278    |
| 15.63kHz / 59.4Hz | NTSC (Closest Spec)  | 384    | 263    |

- MAME information for timing parameters is incorrect.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 14.77kHz / 56.2Hz | MAME                 | 406    | 263    |

### P1/P2 Input Swap Option

- There is a toggle to swap inputs from Player 1 to Player 2. This only swaps inputs for the joystick, it does not effect keyboard inputs.

### Audio Options

- There is a toggle for mixing audio from mono to stereo; MB8842 had this option via dipswitch.

- There are toggles to disable playback of OPM and ADPCM audio or raise the mixing volume the OPM and ADPCM audio channels.

### Overclock Options

- There is a toggle to increase the M68000 frequency from 6MHz to 7.2MHz; this will alter gameplay from it's original state addressing native slowdown of gameplay.

### Native Y/C Output

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments

- There are two H/V toggles, H/V-sync positioning adjust and H/V-sync width adjust. Positioning will move the display for centering on CRT display. The sync width adjust can be used to for sync issues (rolling, flagging etc) without modifying the video timings.

### Scandoubler Options

- Additional toggle to enable the scandoubler without changing ini settings and new scanline option for 100% is available, this draws a black line every other frame. Below is an example.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/cf49d8fa-0e92-4eae-b39c-86551f399020"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/58e9c27f-050e-4452-820f-0428bf5e7097"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/ca3effa0-8cda-4179-b4d6-72d0df4af6f2"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/c0f36b37-03ab-481b-859f-93267e967ca9"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/MegaSys1_A/assets/32810066/a58e4d60-4ea9-4482-a200-d61f6b2f76e1"></td></tr></table> <br>

# PCB Information / Control Layout

| Title                                     | Joystick | Service Menu                                                                                                  | Dip Switches                                                                                               | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|-------------------------------------------|----------|---------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|-----------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **P-47: The Freedom Fighter**             | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Co-Op           | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Ninja Kazan / Iga Ninjyutsuden**        | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Turn Based      | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Phantasm**                              | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Turn Based      | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Saint Dragon**                          | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Turn Based      | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **The Astyanax / The Lord of King**       | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Co-Op           | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Rod-Land**                              | 8-Way    | [**Service Menu**](https://github.com/va7deo/MegaSys1_A/assets/32810066/6b35c179-4f39-4044-94f8-8eaaca18737b) | [**Dip Sheet**](https://github.com/va7deo/MegaSys1_A/assets/32810066/4b649233-2e51-460d-b7c9-5a51b3345455) | Co-Op           | N/A         | Toggling the "Chapter" dipswitch will go from the "First Story (Rescue My Mom)" to the "Second Story (The Unknown Pyramid)". <br><br> You can also insert a coin and press up, up, up, down, down, down, start to enable the second story or up, up, up, down, down, down start to return to the first story on English versions. <br><br> For Japanese versions, the code is reversed for accessing the second story and returning to the first. <br><br> There are three endings to Rod-Land, complete the 31 levels in the first story or second; for the special ending, play either story by inputing the secret code and beating the extra level (32). |
| **Soldam**                                | 8-Way    | [**Service Menu**](https://github.com/va7deo/MegaSys1_A/assets/32810066/57338099-4e76-4973-afb2-7a3141252bb0) | [**Dip Sheet**](https://github.com/va7deo/MegaSys1_A/assets/32810066/0ebbb6b7-2613-4f0e-9174-93e1b2057bd1) | Versus          | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Jitsuryoku!! Pro Yakyuu**               | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Versus          | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Hachoo!**                               | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Co-Op           | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **E.D.F: Earth Defense Force (Prototpe)** | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Co-Op           | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **In Your Face (Prototpe)**               | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Versus          | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Plus Alpha**                            | 8-Way    | **Service Menu**                                                                                              | **Dip Sheet**                                                                                              | Co-Op           | N/A         | Coming soon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

### Keyboard Handler

<br>

- Keyboard inputs mapped to mame defaults for Player 1 / Player 2.

<br>

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-Ctrl</td></tr><tr><td>P1 Bttn 2</td><td>L-Alt</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr><tr><td>P1 Bttn 4</td><td>L-Shift</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr><tr><td>P2 Bttn 4</td><td>W</td></tr> </table>|

