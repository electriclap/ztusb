const shim = @import("tusb_shim");

/// Encapsulate cdc_device API. Only supports one CDC atm.
pub const CDC_Device = struct {
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

    pub fn read(buf: []u8) usize {
        return shim.usbd_cdc_read(buf.ptr, @intCast(buf.len));
    }

    /// returns -1 if no char is read
    pub fn read_char() i32 {
        return shim.usbd_cdc_read_char();
    }

    pub fn read_flush() void {
        shim.usbd_cdc_read_flush();
    }

    pub fn write(buf: []const u8) usize {
        return shim.usbd_cdc_write(buf.ptr, @intCast(buf.len));
    }

    pub fn write_char(char: u8) usize {
        return shim.usbd_cdc_write(&char, 1);
    }

    pub fn write_flush() void {
        shim.usbd_cdc_write_flush();
    }

    /// call through a comptime block to map tiny usb cdc device callbacks to yours
    pub fn export_callbacks(comptime Impl: type) void {
        inline for (.{"on_rx"}) |name| {
            if (!@hasDecl(Impl, name))
                @compileLog("Cdc Device callbacks namesapce is missing `pub fn " ++ name ++ "`");
        }

        const S = struct {
            fn on_rx_callback(itf: u8) callconv(.c) void {
                return Impl.on_rx(itf);
            }
        };
        @export(&S.on_rx_callback, .{ .name = "tud_cdc_rx_cb" });
    }
};
