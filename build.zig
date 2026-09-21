const std = @import("std");

pub const Driver = enum {
    /// Synopsys DWC2 OTG core (STM32F2/F4/F7/H7 OTG_FS/HS, ...)
    dwc2,
    /// ST "USB FS device" core (STM32F0/F1/F3/G4/L4, ...)
    fsdev,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build options
    const driver = b.option(Driver, "driver", "USB device controller driver") orelse .dwc2;
    const cdc = b.option(bool, "cdc", "Compile CDC device class") orelse false;
    const midi = b.option(bool, "midi", "Compile MIDI device class") orelse false;
    const msc = b.option(bool, "msc", "Compile MSC device class") orelse false;
    const hid = b.option(bool, "hid", "Compile HID device class") orelse false;

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
    const ztusb = tusb_translate.addModule("ztusb");

    ztusb.addIncludePath(b.path("src"));
    ztusb.addIncludePath(tusb_dep.path("src"));
    ztusb.addIncludePath(cmsis_core.path("CMSIS/Core/Include"));
    ztusb.addIncludePath(foundation_dep.path("include"));

    const flags: []const []const u8 = &.{"-fno-sanitize=undefined"};

    // adding source files
    var files: std.ArrayList([]const u8) = .empty;
    const a = b.allocator;

    files.appendSlice(a, &.{
        "tusb.c",
        "common/tusb_fifo.c",
        "device/usbd.c",
    }) catch @panic("OOM");

    switch (driver) {
        .dwc2 => files.appendSlice(a, &.{
            "portable/synopsys/dwc2/dcd_dwc2.c",
            "portable/synopsys/dwc2/dwc2_common.c",
        }) catch @panic("OOM"),
        .fsdev => @panic("TODO: fsdev port files"),
    }

    if (cdc) files.append(a, "class/cdc/cdc_device.c") catch @panic("OOM");
    if (midi) files.append(a, "class/midi/midi_device.c") catch @panic("OOM");
    if (msc) files.append(a, "class/msc/msc_device.c") catch @panic("OOM");
    if (hid) files.append(a, "class/hid/hid_device.c") catch @panic("OOM");

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
