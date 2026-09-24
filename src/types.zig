pub const UsbPort = enum(u8) {
    PORT0 = 0,
    PORT1 = 1,
};

pub const UsbSpeed = enum(u32) {
    USB_SPEED_FULL = 0,
    USB_SPEED_LOW = 1,
    USB_SPEED_HIGH = 2,
    USB_SPEED_AUTO = 0xaa,
    USB_SPEED_INVALID = 0xff,
};
