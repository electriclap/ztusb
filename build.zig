const std = @import("std");

pub const Driver = enum {
    dwc2,
    fsdev,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const device = b.option(bool, "device", "Compile as a USB device") orelse false;
    const host = b.option(bool, "host", "Compile as a USB host") orelse false;
    const driver = b.option(Driver, "driver", "USB controller driver") orelse .dwc2;
    const cdc = b.option(bool, "cdc", "Compile CDC class") orelse false;
    // const midi1 = b.option(bool, "midi1", "Compile MIDI1 class") orelse false;
    // const midi2 = b.option(bool, "midi2", "Compile MIDI2 class") orelse false;
    const msc = b.option(bool, "msc", "Compile MSC class") orelse false;
    // const hid = b.option(bool, "hid", "Compile HID class") orelse false;

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

    ztusb.addIncludePath(b.path("src"));
    ztusb.addIncludePath(tusb_dep.path("src"));
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
    }

    if (cdc and device) files.append(a, "class/cdc/cdc_device.c") catch @panic("OOM");
    if (cdc and host) files.append(a, "class/cdc/cdc_host.c") catch @panic("OOM");

    // if (midi1 and device) files.append(a, "class/midi/midi_device.c") catch @panic("OOM");
    // if (midi1 and host) files.append(a, "class/midi/midi_host.c") catch @panic("OOM");

    // if (midi2 and device) files.append(a, "class/midi/midi2_device.c") catch @panic("OOM");
    // if (midi2 and host) files.append(a, "class/midi/midi2_host.c") catch @panic("OOM");

    if (msc and device) files.append(a, "class/msc/msc_device.c") catch @panic("OOM");
    if (msc and host) files.append(a, "class/msc/msc_host.c") catch @panic("OOM");

    // if (hid and device) files.append(a, "class/hid/hid_device.c") catch @panic("OOM");
    // if (hid and host) files.append(a, "class/hid/hid_host.c") catch @panic("OOM");

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
