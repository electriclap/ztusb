const UsbPort = @import("types.zig").UsbPort;
const UsbSpeed = @import("types.zig").UsbSpeed;
const shim = @import("tusb_shim");

pub const Device = struct {
    pub fn init(port: UsbPort, speed: UsbSpeed, clock_speed: u32) void {
        shim.usbd_init(@intFromEnum(port), @intFromEnum(speed), clock_speed);
    }

    pub fn inited() bool {
        return shim.usbd_inited();
    }

    pub fn irq(port: UsbPort) void {
        shim.usbd_irq(@intFromEnum(port));
    }

    pub fn task() void {
        shim.usbd_task();
    }

    pub fn is_connected() bool {
        return shim.usbd_is_connected();
    }

    pub fn is_mounted() bool {
        return shim.usbd_is_mounted();
    }

    pub fn is_suspended() bool {
        return shim.usbd_is_suspended();
    }

    pub fn is_ready() bool {
        return shim.usbd_is_ready();
    }
};
