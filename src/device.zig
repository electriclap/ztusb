const UsbPort = @import("types.zig").UsbPort;
const UsbSpeed = @import("types.zig").UsbSpeed;
const bridge = @import("tusb_bridge");

pub const Device = struct {
    pub fn init(port: UsbPort, speed: UsbSpeed, clock_speed: u32) void {
        bridge.usbd_init(@intFromEnum(port), @intFromEnum(speed), clock_speed);
    }

    pub fn inited() bool {
        return bridge.usbd_inited();
    }

    pub fn irq(port: UsbPort) void {
        bridge.usbd_irq(@intFromEnum(port));
    }

    pub fn task() void {
        bridge.usbd_task();
    }

    pub fn is_connected() bool {
        return bridge.usbd_is_connected();
    }

    pub fn is_mounted() bool {
        return bridge.usbd_is_mounted();
    }

    pub fn is_suspended() bool {
        return bridge.usbd_is_suspended();
    }

    pub fn is_ready() bool {
        return bridge.usbd_is_ready();
    }
};
