pub const MscDevice = @import("msc_device.zig");
pub const shim = @import("tusb_shim");
pub const Device = @import("device.zig").Device;
pub const CdcDevice = @import("cdc_device.zig").CdcDevice;
pub const types = @import("types.zig");

comptime {
    _ = MscDevice;
}

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
