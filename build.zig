const std = @import("std");

pub const TusbDriver = enum {
    dwc2,
    fsdev,
    rp2040,
    pio_usb,
};

const TusbConfig = struct {
    mcu: []const u8 = "OPT_MCU_STM32F4",
    os: []const u8 = "OPT_OS_NONE",
    debug: u8 = 0,

    device: bool = false,
    host: bool = false,
    device_max_speed: []const u8 = "OPT_MODE_FULL_SPEED",
    host_max_speed: []const u8 = "OPT_MODE_FULL_SPEED",

    mem_section: []const u8 = "",
    mem_alignment: u32 = 4,

    endpoint0_size: u32 = 64,

    cdc_device: bool = false,
    msc_device: bool = false,
    hid_device: bool = false,
    midi_device: bool = false,

    cdc_notify: bool = true,
    cdc_rx_bufsize: u32 = 64,
    cdc_tx_bufsize: u32 = 64,
    cdc_rx_epsize: u32 = 64,
    cdc_tx_epsize: u32 = 64,

    midi_rx_bufsize: u32 = 64,
    midi_tx_bufsize: u32 = 64,

    msc_ep_bufsize: u32 = 512,
};

fn createTusbOptions(b: *std.Build) TusbConfig {
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

fn createTusbConfigHeader(b: *std.Build, config: TusbConfig) *std.Build.Step.ConfigHeader {
    const header = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "tusb_config.h",
    }, .{});

    header.addIdent("CFG_TUSB_MCU", config.mcu);
    header.addIdent("CFG_TUSB_OS", config.os);
    header.addValue("CFG_TUSB_DEBUG", u8, config.debug);

    header.addValue("CFG_TUD_ENABLED", bool, config.device);
    header.addValue("CFG_TUH_ENABLED", bool, config.host);

    header.addIdent("CFG_TUD_MAX_SPEED", config.device_max_speed);
    header.addIdent("CFG_TUH_MAX_SPEED", config.host_max_speed);

    var formatted_mem_section: []const u8 = "";
    if (config.mem_section.len > 0) {
        formatted_mem_section = std.fmt.allocPrint(b.allocator, "__attribute__((section(\"{s}\")))", .{config.mem_section}) catch @panic("OOM");
    }
    header.addIdent("CFG_TUSB_MEM_SECTION", formatted_mem_section);

    const formatted_mem_align: []const u8 = std.fmt.allocPrint(b.allocator, "__attribute__ ((aligned({d})))", .{config.mem_alignment}) catch @panic("OOM");
    header.addIdent("CFG_TUSB_MEM_ALIGN", formatted_mem_align);

    header.addValue("CFG_TUD_ENDPOINT0_SIZE", u32, config.endpoint0_size);

    header.addValue("CFG_TUD_CDC", bool, config.cdc_device);
    header.addValue("CFG_TUD_MSC", bool, config.msc_device);
    header.addValue("CFG_TUD_HID", bool, config.hid_device);
    header.addValue("CFG_TUD_MIDI", bool, config.midi_device);

    header.addValue("CFG_TUD_CDC_RX_BUFSIZE", u32, config.cdc_rx_bufsize);
    header.addValue("CFG_TUD_CDC_TX_BUFSIZE", u32, config.cdc_tx_bufsize);
    header.addValue("CFG_TUD_CDC_RX_EPSIZE", u32, config.cdc_rx_epsize);
    header.addValue("CFG_TUD_CDC_TX_EPSIZE", u32, config.cdc_tx_epsize);

    header.addValue("CFG_TUD_MSC_EP_BUFSIZE", u32, config.msc_ep_bufsize);

    header.addValue("CFG_TUD_MIDI_RX_BUFSIZE", u32, config.midi_rx_bufsize);
    header.addValue("CFG_TUD_MIDI_TX_BUFSIZE", u32, config.midi_tx_bufsize);

    return header;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const driver = b.option(TusbDriver, "driver", "USB controller driver") orelse .dwc2;

    const cfg = createTusbOptions(b);

    // we want to expose build options for facilitating usb_descriptors.c file generation
    const options = b.addOptions();
    const member = @typeInfo(TusbConfig).@"struct";
    inline for (member.field_names, member.field_types) |name, FieldType| {
        options.addOption(FieldType, name, @field(cfg, name));
    }

    // config header autogen from build options
    const tusb_config_header = createTusbConfigHeader(b, cfg);

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

    ztusb.linkLibrary(foundation);
    b.modules.put(b.allocator, b.dupe("ztusb"), ztusb) catch @panic("OOM");
}
