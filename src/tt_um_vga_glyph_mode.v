/*
 * Copyright (c) 2024-2025 CJ TORRES
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_glyph_mode(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
    wire hsync, vsync, display_on;
    wire [10:0] hpos;
    wire [9:0] vpos;

    // TinyVGA PMOD
    assign uo_out = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};

    // Unused outputs assigned to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

    wire [7:0] xb = hpos[10:3];
    wire [6:0] x_mix = {xb[7] ^ xb[3], xb[1], xb[4], xb[1], xb[6], xb[0], xb[2]};
    wire [2:0] g_x = hpos[2:0];
    wire [5:0] yb;
    wire [3:0] _unused;
    assign {_unused, yb} = vpos / 10'd12;
    wire [5:0] g_unused;
    wire [3:0] g_y;
    assign {g_unused, g_y} = vpos - {yb, 3'b000} - {1'b0, yb, 2'b00};
    wire hl;

    // Suppress unused signals warning
    wire _unused_ok = &{ena, ui_in[5:2], uio_in};

    reg [9:0] frame;
    reg rst_drop;

    // VGA output
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .mode(ui_in[7:6]),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );

    // glyphs para sa background matrix rain (HAPPY BIRTHDAY YENG)
    glyphs_rom glyphs(
        .c(glyph_index),
        .y(g_y),
        .x(g_x),
        .pixel(hl)
    );

    // palette - Naka-set sa kulay purple/blue tone
    wire [5:0] color;
    palette_rom palettes(
        .cid(y),
        .pid(2'd2), 
        .color(color)
    );

    // Function para sa HAPPY BIRTHDAY YENG (19 characters)
    function [5:0] get_hb_glyph;
        input [5:0] row;
        reg [4:0] idx;
        begin
            idx = row % 5'd19;
            case (idx)
                5'd0:  get_hb_glyph = 6'd7;  // H
                5'd1:  get_hb_glyph = 6'd0;  // A
                5'd2:  get_hb_glyph = 6'd15; // P
                5'd3:  get_hb_glyph = 6'd15; // P
                5'd4:  get_hb_glyph = 6'd24; // Y
                5'd5:  get_hb_glyph = 6'd26; // (space)
                5'd6:  get_hb_glyph = 6'd1;  // B
                5'd7:  get_hb_glyph = 6'd8;  // I
                5'd8:  get_hb_glyph = 6'd17; // R
                5'd9:  get_hb_glyph = 6'd19; // T
                5'd10: get_hb_glyph = 6'd7;  // H
                5'd11: get_hb_glyph = 6'd3;  // D
                5'd12: get_hb_glyph = 6'd0;  // A
                5'd13: get_hb_glyph = 6'd24; // Y
                5'd14: get_hb_glyph = 6'd26; // (space)
                5'd15: get_hb_glyph = 6'd24; // Y
                5'd16: get_hb_glyph = 6'd4;  // E
                5'd17: get_hb_glyph = 6'd13; // N
                5'd18: get_hb_glyph = 6'd6;  // G
                default: get_hb_glyph = 6'd26;
            endcase
        end
    endfunction

    wire [5:0] glyph_index = get_hb_glyph(yb);

    // ==========================================
    // POPUP FEATURE: HAPPY BIRTHDAY MAYENG
    // Maglalabas pagkalipas ng 7 seconds (420 frames)
    // ==========================================
    wire popup_active = (frame >= 10'd420);
    wire in_box_x = (hpos >= 11'd100 && hpos < 11'd540);
    wire in_box_y = (vpos >= 10'd200 && vpos < 10'd280);
    wire box_region = popup_active && in_box_x && in_box_y;

    wire [10:0] box_local_x = hpos - 11'd110;
    wire [9:0]  box_local_y = vpos - 10'd232;
    wire [4:0]  popup_char_col = box_local_x[9:3];
    wire [2:0]  popup_glyph_x  = box_local_x[2:0];
    wire [3:0]  popup_glyph_y  = box_local_y[3:0];

    function [5:0] get_popup_glyph;
        input [4:0] col;
        begin
            case (col)
                5'd0:  get_popup_glyph = 6'd7;  // H
                5'd1:  get_popup_glyph = 6'd0;  // A
                5'd2:  get_popup_glyph = 6'd15; // P
                5'd3:  get_popup_glyph = 6'd15; // P
                5'd4:  get_popup_glyph = 6'd24; // Y
                5'd5:  get_popup_glyph = 6'd26; // (space)
                5'd6:  get_popup_glyph = 6'd1;  // B
                5'd7:  get_popup_glyph = 6'd8;  // I
                5'd8:  get_popup_glyph = 6'd17; // R
                5'd9:  get_popup_glyph = 6'd19; // T
                5'd10: get_popup_glyph = 6'd7;  // H
                5'd11: get_popup_glyph = 6'd3;  // D
                5'd12: get_popup_glyph = 6'd0;  // A
                5'd13: get_popup_glyph = 6'd24; // Y
                5'd14: get_popup_glyph = 6'd26; // (space)
                5'd15: get_popup_glyph = 6'd12; // M
                5'd16: get_popup_glyph = 6'd0;  // A
                5'd17: get_popup_glyph = 6'd24; // Y
                5'd18: get_popup_glyph = 6'd4;  // E
                5'd19: get_popup_glyph = 6'd13; // N
                5'd20: get_popup_glyph = 6'd6;  // G
                default: get_popup_glyph = 6'd26;
            endcase
        end
    endfunction

    wire [5:0] popup_glyph_index = get_popup_glyph(popup_char_col);
    wire popup_text_pixel;

    glyphs_rom popup_glyphs(
        .c(popup_glyph_index),
        .y(popup_glyph_y),
        .x(popup_glyph_x),
        .pixel(popup_text_pixel)
    );

    wire [1:0] a = xb[1:0];
    wire [3:0] b = xb[5:2];
    wire [2:0] d = xb[3:2] + 2'd3;

    wire t = &{xb[0] ^ yb[2] ^ frame[7], xb[1] ^ yb[1] ^ frame[8], xb[2] ^ yb[3] ^ frame[9], xb[3] ^ yb[0]}; // toggle glyph

    // column features (mas mabilis na pagbagsak gamit ang mas mataas na bits ng frame)
    wire s = ^xb[6:0]; // speed of rain
    wire n = xb[1] ^ xb[3] ^ xb[5]; // lit on or off

    wire [6:0] v = (s ? frame[7:1] : frame[8:2]) - yb - x_mix;
    wire [3:0] c = {1'b0, a} + d;
    wire [6:0] e = {3'b000, b} << c;
    wire [6:0] f = v & e;
    wire [6:0] x = v >> a;
    wire [2:0] y = ~x[2:0];
    wire [9:0] drop = {1'b0, yb, 3'd0} >> s;
    wire drop_bit = ({3'd0, x_mix} + drop > frame) & ~rst_drop;
    wire [5:0] glyph_color = {6{drop_bit}} ^ color;

    wire [5:0] z = (&(~v[2:0]) & &(y)) ? 6'd63 : glyph_color;

    // Kulay ng Popup Box at Font
    wire [5:0] popup_box_color = 6'b110011; // Purple box background
    wire [5:0] popup_font_color = 6'b111111; // White text color

    // Final RGB Multiplexer
    wire [5:0] RGB = display_on ? (
        box_region ? (popup_text_pixel ? popup_font_color : popup_box_color) :
        ((hl & ~(|f | n | drop_bit)) ? z : 6'd0)
    ) : 6'd0;

    always @(posedge vsync, negedge rst_n) begin
        if (~rst_n) begin
            rst_drop <= 0;
            frame <= 0;
        end else begin
            if (&frame) begin
                rst_drop <= 1;
            end
            frame <= frame + 1;
        end
    end

endmodule