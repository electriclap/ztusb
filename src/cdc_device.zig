const shim = @import("tusb_shim");

/// Encapsulate cdc_device API. Only supports one CDC atm.
pub const CdcDevice = struct {
    pub fn is_ready() bool {
        return shim.usbd_cdc_is_ready();
    }

    /// return true if the comport is opened
    pub fn is_connected() bool {
        return shim.usbd_cdc_is_connected();
    }

    /// available bytes for reading
    pub fn get_available_bytes() u32 {
        return shim.usbd_cdc_available();
    }

    pub fn read_buf(buf: []u8) usize {
        return shim.usbd_cdc_read(buf.ptr, @intCast(buf.len));
    }

    /// returns -1 if no char is read
    pub fn read_char() i32 {
        return shim.usbd_cdc_read_char();
    }

    pub fn read_flush() void {
        shim.usbd_cdc_read_flush();
    }

    pub fn write_buf(buf: []const u8) usize {
        return shim.usbd_cdc_write(buf.ptr, @intCast(buf.len));
    }

    pub fn write_char(char: u8) usize {
        return shim.usbd_cdc_write(&char, 1);
    }

    pub fn write_flush() void {
        shim.usbd_cdc_write_flush();
    }

    pub fn set_rx_callback(f: RxCallbackFn) void {
        CdcDeviceCallbacks.on_rx = f;
    }
};

// CALLBACKS //

pub const RxCallbackFn = *const fn (itf: u8) void;

const CdcDeviceCallbacks = struct {
    on_rx: RxCallbackFn = default_rx_callback,
};

var cdc_device_callbacks: CdcDeviceCallbacks = .{};

fn default_rx_callback(itf: u8) void {
    _ = itf;
}

export fn tud_cdc_rx_cb(itf: u8) callconv(.c) void {
    return cdc_device_callbacks.on_rx(itf);
}
