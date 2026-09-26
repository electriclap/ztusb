const std = @import("std");

pub const TusbDriver = enum {
    dwc2,
    fsdev,
    rp2040,
    pio_usb,
};

const TusbConfig = struct {
    mcu: []const u8 = "STM32F4",
    os: []const u8 = "NONE",
    debug: u8 = 0,
    tud_enabled: bool = false,
    tuh_enabled: bool = false,
    max_speed: []const u8 = "OPT_MODE_FULL_SPEED",
    mem_section: []const u8 = "",
    mem_alignment: u32 = 4,
    endpoint0_size: u32 = 64,

    cdc_device: bool = false,
    msc_device: bool = false,
    hid_device: bool = false,
    midi_device: bool = false,

    cdc_notify: bool = true,

    cdc_rx_bufsize_hs: u32 = 512,
    cdc_rx_bufsize_fs: u32 = 64,
    cdc_tx_bufsize_hs: u32 = 512,
    cdc_tx_bufsize_fs: u32 = 64,
    cdc_rx_epsize_hs: u32 = 512,
    cdc_rx_epsize_fs: u32 = 64,
    cdc_tx_epsize_hs: u32 = 512,
    cdc_tx_epsize_fs: u32 = 64,

    midi_rx_bufsize_hs: u32 = 512,
    midi_rx_bufsize_fs: u32 = 64,
    midi_tx_bufsize_hs: u32 = 512,
    midi_tx_bufsize_fs: u32 = 64,

    msc_ep_bufsize: u32 = 512,
};

fn readTusbConfig(b: *std.Build) TusbConfig {
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

fn formatTusbConfigHeader(b: *std.Build, cfg: TusbConfig) []const u8 {
    const mem_section_config_str: []const u8 = blk: {
        const section = cfg.mem_section;
        if (section.len == 0) break :blk "";
        break :blk std.fmt.allocPrint(
            b.allocator,
            "__attribute__((section(\"{s}\")))",
            .{section},
        ) catch @panic("OOM");
    };

    return std.fmt.allocPrint(b.allocator,
        \\#ifndef TUSB_CONFIG_H_
        \\#define TUSB_CONFIG_H_
        \\
        \\#ifndef CFG_TUSB_MCU
        \\#define CFG_TUSB_MCU          OPT_MCU_{s}
        \\#endif
        \\
        \\#ifndef CFG_TUSB_OS
        \\#define CFG_TUSB_OS           OPT_OS_{s}
        \\#endif
        \\
        \\#ifndef CFG_TUSB_DEBUG
        \\#define CFG_TUSB_DEBUG        {d}
        \\#endif
        \\
        \\#define CFG_TUD_ENABLED       {d}
        \\#define CFG_TUH_ENABLED       {d}
        \\#define CFG_TUD_MAX_SPEED     {s}
        \\
        \\#ifndef CFG_TUSB_MEM_SECTION
        \\#define CFG_TUSB_MEM_SECTION  {s}
        \\#endif
        \\
        \\#ifndef CFG_TUSB_MEM_ALIGN
        \\#define CFG_TUSB_MEM_ALIGN     __attribute__ ((aligned({d})))
        \\#endif
        \\
        \\#ifndef CFG_TUD_ENDPOINT0_SIZE
        \\#define CFG_TUD_ENDPOINT0_SIZE   {d}
        \\#endif
        \\
        \\#define CFG_TUD_CDC              {d}
        \\#define CFG_TUD_MSC              {d}
        \\#define CFG_TUD_HID              {d}
        \\#define CFG_TUD_MIDI             {d}
        \\#define CFG_TUD_MIDI2            0
        \\
        \\#define CFG_TUH_CDC              0
        \\#define CFG_TUH_MSC              0
        \\#define CFG_TUH_HID              0
        \\#define CFG_TUH_MIDI             0
        \\#define CFG_TUH_MIDI2            0
        \\
        \\
        \\#define CFG_TUD_CDC_NOTIFY        {d}
        \\#define CFG_TUD_CDC_RX_BUFSIZE    (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\#define CFG_TUD_CDC_TX_BUFSIZE    (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\#define CFG_TUD_CDC_RX_EPSIZE     (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\#define CFG_TUD_CDC_TX_EPSIZE     (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\
        \\#define CFG_TUD_MSC_EP_BUFSIZE    {d}
        \\
        \\#define CFG_TUD_MIDI_RX_BUFSIZE   (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\#define CFG_TUD_MIDI_TX_BUFSIZE   (TUD_OPT_HIGH_SPEED ? {d} : {d})
        \\
        \\#endif /* TUSB_CONFIG_H_ */
        \\
    , .{
        cfg.mcu,
        cfg.os,
        cfg.debug,
        @intFromBool(cfg.tud_enabled),
        @intFromBool(cfg.tuh_enabled),
        cfg.max_speed,
        mem_section_config_str,
        cfg.mem_alignment,
        cfg.endpoint0_size,
        @intFromBool(cfg.cdc_device),
        @intFromBool(cfg.msc_device),
        @intFromBool(cfg.hid_device),
        @intFromBool(cfg.midi_device),
        @intFromBool(cfg.cdc_notify),
        cfg.cdc_rx_bufsize_hs,
        cfg.cdc_rx_bufsize_fs,
        cfg.cdc_tx_bufsize_hs,
        cfg.cdc_tx_bufsize_fs,
        cfg.cdc_rx_epsize_hs,
        cfg.cdc_rx_epsize_fs,
        cfg.cdc_tx_epsize_hs,
        cfg.cdc_tx_epsize_fs,
        cfg.msc_ep_bufsize,
        cfg.midi_rx_bufsize_hs,
        cfg.midi_rx_bufsize_fs,
        cfg.midi_tx_bufsize_hs,
        cfg.midi_tx_bufsize_fs,
    }) catch @panic("OOM");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const driver = b.option(TusbDriver, "driver", "USB controller driver") orelse .dwc2;
    const cfg = readTusbConfig(b);

    const options = b.addOptions();

    const member = @typeInfo(TusbConfig).@"struct";
    inline for (member.field_names, member.field_types) |name, FieldType| {
        options.addOption(FieldType, name, @field(cfg, name));
    }

    // config header autogen from build options
    const header_contents = formatTusbConfigHeader(b, cfg);
    const wf = b.addWriteFiles();
    const header = wf.add("tusb_config.h", header_contents);

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
    ztusb.addIncludePath(header.dirname());
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

    ztusb.linkLibrary(foundation);
    b.modules.put(b.allocator, b.dupe("ztusb"), ztusb) catch @panic("OOM");
}
