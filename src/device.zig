const UsbPort = @import("types.zig").UsbPort;
const UsbSpeed = @import("types.zig").UsbSpeed;
const shim = @import("shim_tusb");

pub fn init(port: UsbPort, speed: UsbSpeed, clock_speed: u32) void {
    shim.usb_init(@intFromEnum(port), shim.USB_ROLE_DEVICE, @intFromEnum(speed), clock_speed);
}

pub fn task() void {
    shim.usbd_task();
}

pub fn irq(port: UsbPort) void {
    shim.usbd_irq(@intFromEnum(port));
}

pub const Cdc = struct {
    pub fn isConnected() bool {
        return shim.usbd_cdc_isconnected();
    }
    pub fn available() u32 {
        return shim.usbd_cdc_available();
    }
    pub fn read(buf: []u8) usize {
        return shim.usbd_cdc_read(buf.ptr, @intCast(buf.len));
    }
    pub fn write(buf: []const u8) usize {
        return shim.usbd_cdc_write(buf.ptr, @intCast(buf.len));
    }
    pub fn write_flush() void {
        shim.usbd_cdc_write_flush();
    }
    pub fn read_flush() void {
        shim.usbd_cdc_read_flush();
    }
};
