const std = @import("std");
const TusbDriver = @import("../../build.zig").TusbDriver;
const TusbConfig = @import("../../build.zig").TusbConfig;

pub fn create_tusb_descriptors_file(b: *std.Build, config: TusbConfig) []u8 {
    const fs_configuration = get_fs_conf_arr_and_itf_num_enum(b, config);
    const str_descriptors = get_string_descriptors(b, config);

    const device_class: []const u8 = if (config.cdc_device == true) "TUSB_CLASS_MISC" else "0x00";
    const device_subclass: []const u8 = if (config.cdc_device == true) "MISC_SUBCLASS_COMMON" else "0x00";
    const device_protocol: []const u8 = if (config.cdc_device == true) "MISC_PROTOCOL_IAD" else "0x00";

    const descriptors_file: []u8 = b.allocator.print(
        \\/*
        \\ * The MIT License (MIT)
        \\ *
        \\ * Copyright (c) 2019 Ha Thach (tinyusb.org)
        \\ *
        \\ * Permission is hereby granted, free of charge, to any person obtaining a copy
        \\ * of this software and associated documentation files (the "Software"), to deal
        \\ * in the Software without restriction, including without limitation the rights
        \\ * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        \\ * copies of the Software, and to permit persons to whom the Software is
        \\ * furnished to do so, subject to the following conditions:
        \\ *
        \\ * The above copyright notice and this permission notice shall be included in
        \\ * all copies or substantial portions of the Software.
        \\ *
        \\ * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        \\ * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        \\ * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        \\ * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        \\ * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        \\ * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        \\ * THE SOFTWARE.
        \\ *
        \\ */
        \\
        \\#include "tusb.h"
        \\#include "tusb_config.h"
        \\
        \\//--------------------------------------------------------------------+
        \\// Device Descriptors
        \\//--------------------------------------------------------------------+
        \\static tusb_desc_device_t const desc_device = {{
        \\    .bLength            = sizeof(tusb_desc_device_t),
        \\    .bDescriptorType    = TUSB_DESC_DEVICE,
        \\    .bcdUSB             = 0x{x},
        \\    .bDeviceClass       = {s},
        \\    .bDeviceSubClass    = {s},
        \\    .bDeviceProtocol    = {s},
        \\    .bMaxPacketSize0    = CFG_TUD_ENDPOINT0_SIZE,
        \\
        \\    .idVendor           = 0x{x},
        \\    .idProduct          = 0x{x},
        \\    .bcdDevice          = 0x0100,
        \\
        \\    .iManufacturer      = 0x01,
        \\    .iProduct           = 0x02,
        \\    .iSerialNumber      = 0x03,
        \\
        \\    .bNumConfigurations = 0x01
        \\}};
        \\
        \\uint8_t const *tud_descriptor_device_cb(void) {{
        \\  return (uint8_t const *) &desc_device;
        \\}}
        \\
        \\{s}
        \\
        \\uint8_t const *tud_descriptor_configuration_cb(uint8_t index) {{
        \\  (void) index; // for multiple configurations
        \\  return desc_fs_configuration;
        \\}}
        \\
        \\enum {{
        \\  STRID_LANGID = 0,
        \\  STRID_MANUFACTURER,
        \\  STRID_PRODUCT,
        \\  STRID_SERIAL,
        \\}};
        \\
        \\{s}
        \\
        \\static uint16_t _desc_str[32 + 1];
        \\
        \\uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid) {{
        \\  (void) langid;
        \\  size_t chr_count;
        \\
        \\  switch ( index ) {{
        \\    case STRID_LANGID:
        \\      memcpy(&_desc_str[1], string_desc_arr[0], 2);
        \\      chr_count = 1;
        \\      break;
        \\
        \\    default:
        \\      if ( !(index < sizeof(string_desc_arr) / sizeof(string_desc_arr[0])) ) {{ return NULL; }}
        \\
        \\      const char *str = string_desc_arr[index];
        \\
        \\      // Cap at max char
        \\      chr_count = strlen(str);
        \\      size_t const max_count = sizeof(_desc_str) / sizeof(_desc_str[0]) - 1; // -1 for string type
        \\      if ( chr_count > max_count ) {{ chr_count = max_count; }}
        \\
        \\      // Convert ASCII string into UTF-16
        \\      for ( size_t i = 0; i < chr_count; i++ ) {{
        \\        _desc_str[1 + i] = str[i];
        \\      }}
        \\      break;
        \\  }}
        \\
        \\  _desc_str[0] = (uint16_t) ((TUSB_DESC_STRING << 8) | (2 * chr_count + 2));
        \\  return _desc_str;
        \\}}
    ,
        .{ config.bcd, device_class, device_subclass, device_protocol, config.vid, config.pid, fs_configuration, str_descriptors },
    ) catch @panic("OOM");

    return descriptors_file;
}

/// Helper function that builds these two data structures :
///
///enum {
///  ITF_NUM_CDC = 0,
///  ITF_NUM_CDC_DATA,
///  ITF_NUM_MSC,
///  ITF_NUM_TOTAL
///};
///
///static uint8_t const desc_fs_configuration[] = {
///    // Config number, interface count, string index, total length, attribute, power in mA
///    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),
///
///    //Interface number, string index, EP notification address and size, EP data address (out, in) and size.
///    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, 4, EPNUM_CDC_NOTIF, 16, EPNUM_CDC_OUT, EPNUM_CDC_IN, 64),
///
///    //Interface number, string index, EP Out & EP In address, EP size
///    TUD_MSC_DESCRIPTOR(ITF_NUM_MSC, 5, EPNUM_MSC_OUT, EPNUM_MSC_IN, 64),
///};
fn get_fs_conf_arr_and_itf_num_enum(b: *std.Build, config: TusbConfig) []const u8 {
    var next_index: u8 = 4; // 0 : language, 1 : manufacturer, 2 : product, 3 : unique ID, 4 and else : classes

    var itf_num_enum_arr: std.ArrayList([]const u8) = .empty;
    var fs_config_arr: std.ArrayList([]const u8) = .empty;

    itf_num_enum_arr.append(b.allocator, "enum {\n") catch @panic("OOM");

    const start_fs_config = b.allocator.print(
        \\static uint8_t const desc_fs_configuration[] = {{
        \\    // Config number, interface count, string index, total length, attribute, power in mA
        \\    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),
        \\
    ,
        .{},
    ) catch @panic("OOM");

    fs_config_arr.append(b.allocator, start_fs_config) catch @panic("OOM");

    // TODO there must be a better way? LUT?
    inline for (.{ "cdc_device", "msc_device", "midi_device" }, 0..) |name, i| {
        if (@field(config, name) == true) {
            switch (i) {
                0 => {
                    const tmp_str = b.allocator.print(
                        \\    
                        \\    //Interface number, string index, EP notification address and size, EP data address (out, in) and size.
                        \\    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, {d}, EPNUM_CDC_NOTIF, 16, EPNUM_CDC_OUT, EPNUM_CDC_IN, 64),
                        \\
                    ,
                        .{next_index},
                    ) catch @panic("OOM");

                    fs_config_arr.append(b.allocator, tmp_str) catch @panic("OOM");

                    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_CDC,\n") catch @panic("OOM");
                    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_CDC_DATA,\n") catch @panic("OOM");
                },
                1 => {
                    const tmp_str = b.allocator.print(
                        \\    
                        \\    //Interface number, string index, EP Out & EP In address, EP size
                        \\    TUD_MSC_DESCRIPTOR(ITF_NUM_MSC, {d}, EPNUM_MSC_OUT, EPNUM_MSC_IN, 64),
                        \\
                    ,
                        .{next_index},
                    ) catch @panic("OOM");

                    fs_config_arr.append(b.allocator, tmp_str) catch @panic("OOM");

                    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_MSC,\n") catch @panic("OOM");
                },
                2 => {
                    const tmp_str = b.allocator.print(
                        \\    
                        \\    // Interface number, string index, EP Out & EP In address, EP size
                        \\    TUD_MIDI_DESCRIPTOR(ITF_NUM_MIDI, {d}, EPNUM_MIDI_OUT, EPNUM_MIDI_IN, 64),
                        \\
                    ,
                        .{next_index},
                    ) catch @panic("OOM");

                    fs_config_arr.append(b.allocator, tmp_str) catch @panic("OOM");

                    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_MIDI,\n") catch @panic("OOM");
                    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_MIDI_STREAMING,\n") catch @panic("OOM");
                },
                else => unreachable,
            }

            next_index += 1;
        }
    }

    // last lines
    fs_config_arr.append(b.allocator, "};") catch @panic("OOM");
    itf_num_enum_arr.append(b.allocator, "  ITF_NUM_TOTAL\n};\n\n") catch @panic("OOM");

    // concatening the two data structures
    itf_num_enum_arr.appendSlice(b.allocator, fs_config_arr.items) catch @panic("OOM");

    return std.mem.concat(b.allocator, u8, itf_num_enum_arr.items) catch @panic("OOM");
}

// TODO refactor with Arraylist
fn get_string_descriptors(b: *std.Build, config: TusbConfig) []const u8 {
    const str_desc_first_lines = b.allocator.print(
        \\// array of pointer to string descriptors
        \\static char const *string_desc_arr[] = {{
        \\    (const char[]) {{ 0x09, 0x04 }},   // 0: is supported language is English (0x0409)
        \\    "{s}",                             // 1: Manufacturer
        \\    "{s}",                             // 2: Product
        \\    "{s}",                             // 3: Unique ID
    ,
        .{ config.manufacturer, config.product, config.id },
    ) catch @panic("OOM");

    // TODO DRY with an ArrayList
    var str_desc_cdc: []const u8 = "";
    if (config.cdc_device == true) {
        str_desc_cdc = b.allocator.print(
            \\    "{s}",
        , .{config.cdc_str_desc}) catch @panic("OOM");
    }

    var str_desc_msc: []const u8 = "";
    if (config.msc_device == true) {
        str_desc_msc = b.allocator.print(
            \\    "{s}",
        , .{config.msc_str_desc}) catch @panic("OOM");
    }

    var str_desc_midi: []const u8 = "";
    if (config.midi_device == true) {
        str_desc_midi = b.allocator.print(
            \\    "{s}",
        , .{config.midi_str_desc}) catch @panic("OOM");
    }

    const str_desc_last_line = b.allocator.print(
        \\ }};
    , .{}) catch @panic("OOM");

    // TODO this prints empty lines. It works, but i don't like it.
    return b.allocator.print(
        \\{s}
        \\{s}
        \\{s}
        \\{s}
        \\{s}
    ,
        .{ str_desc_first_lines, str_desc_cdc, str_desc_msc, str_desc_midi, str_desc_last_line },
    ) catch @panic("OOM");
}
