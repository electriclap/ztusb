pub const msc = @import("tud_msc_callbacks.zig");
pub const shim = @import("tusb_shim");
pub const Device = @import("device.zig").Device;
pub const CdcDevice = @import("cdc_device.zig").CdcDevice;
pub const types = @import("types.zig");

comptime {
    _ = msc;
}
