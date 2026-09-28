const std = @import("std");
const TusbDriver = @import("src/build_utils/build_types.zig").TusbDriver;
const TusbConfig = @import("src/build_utils/build_types.zig").TusbConfig;

const GenConfig = @import("src/build_utils/generate_config_h.zig");

fn create_tusb_build_options(b: *std.Build) TusbConfig {
    var cfg: TusbConfig = .{};

    const member = @typeInfo(TusbConfig).@"struct";
    inline for (member.field_names, member.field_types) |name, FieldType| {
        const default = @field(cfg, name);
        const value = b.option(
            FieldType,
            name,
            "TinyUSB config: " ++ name,
        ) orelse default;

        @field(cfg, name) = value;
    }

    return cfg;
}

fn create_tusb_descriptors_file(b: *std.Build, config: TusbConfig) []u8 {
    var next_index: u8 = 4;

    var cdc_index: u8 = 0;
    var msc_index: u8 = 0;

    var fs_config_cdc: []u8 = "";
    // var string_desc_cdc: []u8 = "";

    var fs_config_msc: []u8 = "";
    // var string_desc_msc: []u8 = "";

    if (config.cdc_device == true) {
        cdc_index = next_index;
        next_index += 1;
        fs_config_cdc = b.allocator.print(
            "TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, 4, EPNUM_CDC_NOTIF, 16, EPNUM_CDC_OUT, EPNUM_CDC_IN, 64),",
            .{},
        ) catch @panic("OOM");
    }

    if (config.msc_device == true) {
        msc_index = next_index;
        next_index += 1;
        fs_config_msc = b.allocator.print(
            "TUD_MSC_DESCRIPTOR(ITF_NUM_MSC, 5, EPNUM_MSC_OUT, EPNUM_MSC_IN, 64),",
            .{},
        ) catch @panic("OOM");
    }

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
        \\
        \\//--------------------------------------------------------------------+
        \\// Device Descriptors
        \\//--------------------------------------------------------------------+
        \\static tusb_desc_device_t const desc_device = {{
        \\    .bLength            = sizeof(tusb_desc_device_t),
        \\    .bDescriptorType    = TUSB_DESC_DEVICE,
        \\    .bcdUSB             = 0x{x},
        \\    .bDeviceClass       = TUSB_CLASS_MISC,
        \\    .bDeviceSubClass    = MISC_SUBCLASS_COMMON,
        \\    .bDeviceProtocol    = MISC_PROTOCOL_IAD,
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
        \\enum {{ // TODO
        \\  ITF_NUM_CDC = 0,
        \\  ITF_NUM_CDC_DATA,
        \\  ITF_NUM_MSC,
        \\  ITF_NUM_TOTAL
        \\}};
        \\
        \\static uint8_t const desc_fs_configuration[] = {{
        \\    // Config number, interface count, string index, total length, attribute, power in mA
        \\    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),
        \\
        \\    // Interface number, string index, EP notification address and size, EP data address (out, in) and size.
        \\    {s}
        \\
        \\    // Interface number, string index, EP Out & EP In address, EP size
        \\    {s}
        \\}};
        \\
        \\
        \\uint8_t const *tud_descriptor_configuration_cb(uint8_t index) {{
        \\  (void) index; // for multiple configurations
        \\  return desc_fs_configuration;
        \\}}
        \\
        \\
        \\enum {{
        \\  STRID_LANGID = 0,
        \\  STRID_MANUFACTURER,
        \\  STRID_PRODUCT,
        \\  STRID_SERIAL,
        \\}};
        \\
        \\// array of pointer to string descriptors
        \\static char const *string_desc_arr[] = {{
        \\    (const char[]) {{ 0x09, 0x04 }}, // 0: is supported language is English (0x0409)
        \\    "TinyUSB",                     // 1: Manufacturer // TODO
        \\    "TinyUSB Device",              // 2: Product // TODO
        \\    {s},                           // 3: Serials will use unique ID if possible
        \\    "TinyUSB CDC", // TODO
        \\    "TinyUSB MSC", // TODO
        \\}};
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
    , .{ config.bcd, config.vid, config.pid, fs_config_cdc, fs_config_msc, config.id }) catch @panic("OOM");

    return descriptors_file;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const driver = b.option(TusbDriver, "driver", "USB controller driver") orelse .dwc2;

    const cfg = create_tusb_build_options(b);

    // we want to expose build options for facilitating usb_descriptors.c file generation
    const options = b.addOptions();
    const member = @typeInfo(TusbConfig).@"struct";
    inline for (member.field_names, member.field_types) |name, FieldType| {
        options.addOption(FieldType, name, @field(cfg, name));
    }

    // config header autogen from build options
    const tusb_config_header = GenConfig.create_tusb_config_header(b, cfg);

    const descriptors_file: []const u8 = create_tusb_descriptors_file(b, cfg);
    const wf = b.addWriteFiles();
    const descriptors_c = wf.add("usb_descriptors.c", descriptors_file);

    // dependencies
    const tusb_dep = b.dependency("tinyusb", .{});
    const cmsis_core = b.dependency("CMSIS_6", .{});

    const foundation_dep = b.dependency("foundationlibc", .{
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    const foundation = foundation_dep.artifact("foundation");

    // shim module
    const tusb_translate = b.addTranslateC(.{
        .root_source_file = b.path("src/tusb_shim.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });
    tusb_translate.addIncludePath(foundation_dep.path("include"));

    // Actual module
    const ztusb = b.addModule("ztusb", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    ztusb.addImport("tusb_shim", tusb_translate.createModule());
    ztusb.addImport("build_options", options.createModule());

    ztusb.addIncludePath(b.path("src"));
    ztusb.addIncludePath(tusb_dep.path("src"));
    ztusb.addIncludePath(tusb_config_header.getOutputDir());
    ztusb.addIncludePath(cmsis_core.path("CMSIS/Core/Include"));
    ztusb.addIncludePath(foundation_dep.path("include"));

    const flags: []const []const u8 = &.{
        "-std=c11",
        "-fno-sanitize=undefined",
        "-Wno-pointer-to-int-cast",
    };

    var files: std.ArrayList([]const u8) = .empty;
    const a = b.allocator;

    files.appendSlice(a, &.{
        "tusb.c",
        "common/tusb_fifo.c",
        "device/usbd.c",
        "host/hub.c",
        "host/usbh.c",
        "class/cdc/cdc_device.c",
        "class/cdc/cdc_host.c",
        "class/msc/msc_device.c",
        "class/msc/msc_host.c",
        "class/midi/midi_device.c",
        "class/midi/midi_host.c",
        "class/midi/midi2_device.c",
        "class/midi/midi2_host.c",
        "class/hid/hid_device.c",
        "class/hid/hid_host.c",
        "class/audio/audio_device.c",
        // "class/audio/audio_host.c", Audio host will be supported in tinyusb V 0.22.0
        "class/mtp/mtp_device.c",
    }) catch @panic("OOM");

    switch (driver) {
        .dwc2 => files.appendSlice(a, &.{
            "portable/synopsys/dwc2/dcd_dwc2.c",
            "portable/synopsys/dwc2/dwc2_common.c",
            "portable/synopsys/dwc2/hcd_dwc2.c",
        }) catch @panic("OOM"),
        .fsdev => files.appendSlice(a, &.{
            "portable/st/stm32_fsdev/dcd_stm32_fsdev.c",
            "portable/st/stm32_fsdev/fsdev_common.c",
            "portable/st/stm32_fsdev/hcd_stm32_fsdev.c",
        }) catch @panic("OOM"),
        .rp2040 => files.appendSlice(a, &.{
            "portable/raspberrypi/rp2040/rp2040_usb.c",
            "portable/raspberrypi/rp2040/dcd_rp2040.c",
            "portable/raspberrypi/rp2040/hcd_rp2040.c",
        }) catch @panic("OOM"),
        .pio_usb => files.appendSlice(a, &.{
            "portable/raspberrypi/pio_usb/dcd_pio_usb.c",
            "portable/raspberrypi/pio_usb/hcd_pio_usb.c",
        }) catch @panic("OOM"),
    }

    ztusb.addCSourceFiles(.{
        .root = tusb_dep.path("src"),
        .files = files.items,
        .flags = flags,
    });

    ztusb.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{"tusb_shim.c"},
        .flags = flags,
    });

    ztusb.addCSourceFile(.{
        .file = descriptors_c,
        .flags = flags,
    });

    // for debug
    b.getInstallStep().dependOn(
        &b.addInstallFileWithDir(descriptors_c, .prefix, "usb_descriptors.c").step,
    );
    b.getInstallStep().dependOn(
        &b.addInstallFileWithDir(tusb_config_header.getOutputFile(), .prefix, "tusb_config.h").step,
    );

    ztusb.linkLibrary(foundation);
    b.modules.put(b.allocator, b.dupe("ztusb"), ztusb) catch @panic("OOM");
}
