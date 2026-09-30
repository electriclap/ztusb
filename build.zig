const std = @import("std");

const GenDescriptors = @import("src/build_utils/generate_descriptors_c.zig");
const GenConfig = @import("src/build_utils/generate_config_h.zig");

pub const TusbDriver = enum {
    dwc2,
    fsdev,
    rp2040,
    pio_usb,
};

pub const TusbConfig = struct {
    pid: u16,
    vid: u16,
    bcd: u16,
    id: []const u8,

    manufacturer: []const u8,
    product: []const u8,

    mcu: []const u8,
    os: []const u8,
    debug: u8,

    device: bool,
    host: bool,
    device_max_speed: []const u8,
    host_max_speed: []const u8,

    mem_section: []const u8,
    mem_alignment: u32,

    endpoint0_size: u32,

    cdc_device: bool,
    msc_device: bool,
    hid_device: bool,
    midi_device: bool,

    cdc_str_desc: []const u8,
    cdc_notify: bool,
    cdc_rx_bufsize: u32,
    cdc_tx_bufsize: u32,
    cdc_rx_epsize: u32,
    cdc_tx_epsize: u32,

    midi_str_desc: []const u8,
    midi_rx_bufsize: u32,
    midi_tx_bufsize: u32,

    msc_str_desc: []const u8,
    msc_ep_bufsize: u32,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const driver = b.option(TusbDriver, "driver", "USB controller driver") orelse .dwc2;

    const cfg = TusbConfig{
        .pid = b.option(u16, "pid", "USB PID") orelse 0x4001,
        .vid = b.option(u16, "vid", "USB VID") orelse 0xcafe,
        .bcd = b.option(u16, "bcd", "USB BCD") orelse 0x0200,
        .id = b.option([]const u8, "id", "Unique ID") orelse "000000000001",

        .manufacturer = b.option([]const u8, "manufacturer", "Manufacturer string descriptor") orelse "Ztusb",
        .product = b.option([]const u8, "product", "Product string descriptor") orelse "Ztusb device",

        .mcu = b.option([]const u8, "mcu", "MCU family option, e.g. for STM32F4, -> OPT_MCU_STM32F4") orelse "OPT_MCU_STM32F4",
        .os = b.option([]const u8, "os", "RTOS name option, e.g. for no os, -> OPT_OS_NONE") orelse "OPT_OS_NONE",
        .debug = b.option(u8, "debug", "CFG_TUSB_DEBUG level") orelse 0,

        .device = b.option(bool, "device", "Enable USB device stack") orelse false,
        .host = b.option(bool, "host", "Enable USB host stack") orelse false,
        .device_max_speed = b.option([]const u8, "device_max_speed", "CFG_TUD_MAX_SPEED value") orelse "OPT_MODE_FULL_SPEED",
        .host_max_speed = b.option([]const u8, "host_max_speed", "CFG_TUD_MAX_SPEED value") orelse "OPT_MODE_FULL_SPEED",

        .mem_section = b.option([]const u8, "mem_section", "RAM section name for DMA buffers (e.g. .dma_buffer)") orelse "",
        .mem_alignment = b.option(u32, "mem_align", "CFG_TUSB_MEM_ALIGN value") orelse 4,

        .endpoint0_size = b.option(u32, "ep0_size", "CFG_TUD_ENDPOINT0_SIZE") orelse 64,

        .cdc_device = b.option(bool, "cdc_device", "Enable CDC class for device") orelse false,
        .msc_device = b.option(bool, "msc_device", "Enable MSC class for device") orelse false,
        .hid_device = b.option(bool, "hid_device", "Enable HID class for device") orelse false,
        .midi_device = b.option(bool, "midi_device", "Enable MIDI class for device") orelse false,

        .cdc_str_desc = b.option([]const u8, "cdc_str_desc", "CDC device string descriptor") orelse "Ztusb CDC",
        .cdc_notify = b.option(bool, "cdc_notify", "Enable CDC notify endpoint") orelse true,
        .cdc_rx_bufsize = b.option(u32, "cdc_rx_bufsize", "") orelse 64,
        .cdc_tx_bufsize = b.option(u32, "cdc_tx_bufsize", "") orelse 64,
        .cdc_rx_epsize = b.option(u32, "cdc_rx_epsize", "") orelse 64,
        .cdc_tx_epsize = b.option(u32, "cdc_tx_epsize", "") orelse 64,

        .midi_str_desc = b.option([]const u8, "midi_str_desc", "MIDI device string descriptor") orelse "Ztusb MIDI",
        .midi_rx_bufsize = b.option(u32, "midi_rx_bufsize", "") orelse 64,
        .midi_tx_bufsize = b.option(u32, "midi_tx_bufsize", "") orelse 64,

        .msc_str_desc = b.option([]const u8, "msc_str_desc", "MSC device string descriptor") orelse "Ztusb MSC",
        .msc_ep_bufsize = b.option(u32, "msc_ep_bufsize", "") orelse 512,
    };

    // we want to expose build options for facilitating usb_descriptors.c file generation
    const options = b.addOptions();
    const member = @typeInfo(TusbConfig).@"struct";
    inline for (member.field_names, member.field_types) |name, FieldType| {
        options.addOption(FieldType, name, @field(cfg, name));
    }

    // config header autogen from build options
    const tusb_config_header = GenConfig.create_tusb_config_header(b, cfg);

    // usb_descriptors autogen from build options
    const descriptors_file: []const u8 = GenDescriptors.create_tusb_descriptors_file(b, cfg);
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
        .root_source_file = b.path("src/c_bridge/tusb_bridge.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });
    tusb_translate.addIncludePath(foundation_dep.path("include"));

    // Actual library module
    const ztusb = b.addModule("ztusb", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    ztusb.addImport("tusb_bridge", tusb_translate.createModule());
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
        // "class/audio/audio_host.c", // TODO add Audio host when tinyusb V 0.22.0 is released
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
        .root = b.path("src/c_bridge/"),
        .files = &.{"tusb_bridge.c"},
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
