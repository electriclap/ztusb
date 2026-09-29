const shim = @import("tusb_shim");

pub const MSC_Device = struct {
    pub fn set_sense(lun: u8, sense_key: u8, add_sense_code: u8, add_sense_qualifier: u8) bool {
        return shim.usbd_msc_set_sense(lun, sense_key, add_sense_code, add_sense_qualifier);
    }

    pub fn async_io_done(bytes_io: i32, in_isr: bool) bool {
        return shim.usbd_msc_async_io_done(bytes_io, in_isr);
    }

    /// TODO add optional callbacks.
    pub fn export_msc_callbacks(comptime Impl: type) void {
        inline for (.{ "inquiry", "test_unit_ready", "capacity", "start_stop", "read10", "write10", "scsi" }) |name| {
            if (!@hasDecl(Impl, name))
                @compileError("MSC callbacks implementation is missing `pub fn " ++ name ++ "`");
        }

        const S = struct {
            fn inquiry_callback(lun: u8, vendor_id: *[8]u8, product_id: *[16]u8, product_rev: *[4]u8) void {
                return Impl.inquiry(lun, vendor_id, product_id, product_rev);
            }

            fn test_unit_ready_callback(lun: u8) callconv(.c) bool {
                return Impl.test_unit_ready(lun);
            }

            fn capacity_callback(lun: u8, block_count: *u32, block_size: *u16) callconv(.c) void {
                return Impl.capacity(lun, block_count, block_size);
            }

            fn start_stop_callback(lun: u8, power_condition: u8, start: bool, load_eject: bool) callconv(.c) bool {
                return Impl.start_stop(lun, power_condition, start, load_eject);
            }

            fn read10_callback(lun: u8, lba: u32, off: u32, buf: [*]u8, size: u32) callconv(.c) i32 {
                return Impl.read10(lun, lba, off, buf[0..size]);
            }

            fn write10_callback(lun: u8, lba: u32, offset: u32, buffer: [*]const u8, bufsize: u32) callconv(.c) i32 {
                return Impl.write10(lun, lba, offset, buffer, bufsize);
            }

            fn scsi_callback(lun: u8, scsi_cmd: *const [16]u8, buffer: ?*anyopaque, bufsize: u16) callconv(.c) i32 {
                return Impl.scsi(lun, scsi_cmd, buffer, bufsize);
            }
        };
        @export(&S.inquiry, .{ .name = "tud_msc_inquiry_cb" });
        @export(&S.test_unit_ready, .{ .name = "tud_msc_test_unit_ready_cb" });
        @export(&S.capacity, .{ .name = "tud_msc_capacity_cb" });
        @export(&S.start_stop, .{ .name = "tud_msc_start_stop_cb" });
        @export(&S.read10, .{ .name = "tud_msc_read10_cb" });
        @export(&S.write10, .{ .name = "tud_msc_write10_cb" });
        @export(&S.scsi, .{ .name = "tud_msc_scsi_cb" });
    }
};

pub const MSC_TestDisk = struct {};
