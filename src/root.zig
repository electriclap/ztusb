const build_options = @import("build_options");

pub const bridge = @import("tusb_bridge");
pub const types = @import("types.zig");

pub const Device = @import("device.zig").Device;
pub const CDC_Device = @import("cdc_device.zig").CDC_Device;

pub const MSC_Device = @import("msc_device.zig").MSC_Device;
pub const MSC_TestDisk = @import("msc_device.zig").MSC_TestDisk;

pub const MIDI_Device = @import("midi_device.zig").MIDI_Device;

// GENERAL CALLBACKS //

pub const MillisCallbackFn = *const fn () u32;
var millis_callback: MillisCallbackFn = default_millis_callback;

fn default_millis_callback() u32 {
    return 0;
}

pub fn set_millis_callback(f: MillisCallbackFn) void {
    millis_callback = f;
}

export fn tusb_time_millis_api() callconv(.c) u32 {
    return millis_callback();
}
