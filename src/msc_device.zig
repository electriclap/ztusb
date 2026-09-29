const std = @import("std");
const shim = @import("tusb_shim");

pub const MSC_Device = struct {
    pub fn set_sense(lun: u8, sense_key: u8, add_sense_code: u8, add_sense_qualifier: u8) bool {
        return shim.usbd_msc_set_sense(lun, sense_key, add_sense_code, add_sense_qualifier);
    }

    pub fn async_io_done(bytes_io: i32, in_isr: bool) bool {
        return shim.usbd_msc_async_io_done(bytes_io, in_isr);
    }

    /// TODO add optional callbacks.
    pub fn export_callbacks(comptime Impl: type) void {
        inline for (.{ "inquiry", "test_unit_ready", "capacity", "start_stop", "read10", "write10", "scsi" }) |name| {
            if (!@hasDecl(Impl, name))
                @compileError("MSC callbacks implementation is missing `pub fn " ++ name ++ "`");
        }

        const S = struct {
            fn inquiry_callback(lun: u8, vendor_id: *[8]u8, product_id: *[16]u8, product_rev: *[4]u8) callconv(.c) void {
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
        @export(&S.inquiry_callback, .{ .name = "tud_msc_inquiry_cb" });
        @export(&S.test_unit_ready_callback, .{ .name = "tud_msc_test_unit_ready_cb" });
        @export(&S.capacity_callback, .{ .name = "tud_msc_capacity_cb" });
        @export(&S.start_stop_callback, .{ .name = "tud_msc_start_stop_cb" });
        @export(&S.read10_callback, .{ .name = "tud_msc_read10_cb" });
        @export(&S.write10_callback, .{ .name = "tud_msc_write10_cb" });
        @export(&S.scsi_callback, .{ .name = "tud_msc_scsi_cb" });
    }
};

var ejected: bool = false;
const DISK_BLOCK_NUM: u32 = 16;
const DISK_BLOCK_SIZE: u32 = 512;

const README_CONTENTS =
    "This is tinyusb's MassStorage Class demo.\r\n\r\n" ++
    "If you find any bugs or get any questions, feel free to file an\r\n" ++
    "issue at github.com/hathach/tinyusb";

pub var msc_disk: [DISK_BLOCK_NUM][DISK_BLOCK_SIZE]u8 = blk: {
    var d = std.mem.zeroes([DISK_BLOCK_NUM][DISK_BLOCK_SIZE]u8);

    //------------- Block0: Boot Sector -------------//
    // byte_per_sector    = DISK_BLOCK_SIZE; fat12_sector_num_16  = DISK_BLOCK_NUM;
    // sector_per_cluster = 1; reserved_sectors = 1;
    // fat_num            = 1; fat12_root_entry_num = 16;
    // sector_per_fat     = 1; sector_per_track = 1; head_num = 1; hidden_sectors = 0;
    // drive_number       = 0x80; media_type = 0xf8; extended_boot_signature = 0x29;
    // filesystem_type    = "FAT12   "; volume_serial_number = 0x1234; volume_label = "TinyUSB MSC";
    const boot = [_]u8{
        0xEB, 0x3C, 0x90, 0x4D, 0x53, 0x44, 0x4F, 0x53, 0x35, 0x2E, 0x30, 0x00, 0x02, 0x01, 0x01, 0x00,
        0x01, 0x10, 0x00, 0x10, 0x00, 0xF8, 0x01, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x29, 0x34, 0x12, 0x00, 0x00, 'T',  'i',  'n',  'y',  'U',
        'S',  'B',  ' ',  'M',  'S',  'C',  0x46, 0x41, 0x54, 0x31, 0x32, 0x20, 0x20, 0x20, 0x00, 0x00,
    };
    @memcpy(d[0][0..boot.len], &boot);
    // FAT magic code at offset 510-511
    d[0][510] = 0x55;
    d[0][511] = 0xAA;

    //------------- Block1: FAT12 Table -------------//
    const fat = [_]u8{
        0xF8, 0xFF, 0xFF, 0xFF, 0x0F, // first 2 entries must be F8FF, third entry is cluster end of readme file
    };
    @memcpy(d[1][0..fat.len], &fat);

    //------------- Block2: Root Directory -------------//
    const root = [_]u8{
        // first entry is volume label
        'T',  'i',  'n',  'y',  'U',  'S',  'B',  ' ',  'M',  'S',  'C',  0x08, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4F, 0x6D, 0x65, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        // second entry is readme file
        'R',  'E',  'A',  'D',  'M',  'E',  ' ',  ' ',  'T',  'X',  'T',  0x20, 0x00, 0xC6, 0x52, 0x6D,
        0x65, 0x43, 0x65, 0x43, 0x00, 0x00, 0x88, 0x6D, 0x65, 0x43, 0x02, 0x00,
        README_CONTENTS.len, 0x00, 0x00, 0x00, // readme's files size (4 Bytes)
    };
    @memcpy(d[2][0..root.len], &root);

    //------------- Block3: Readme Content -------------//
    @memcpy(d[3][0..README_CONTENTS.len], README_CONTENTS);

    break :blk d;
};

/// Read-Only test MSC implementation
/// Shows a readme.txt file on disk with content
/// directly taken from tiny usb cdc+msc device example
pub const MSC_TestDisk = struct {
    pub fn inquiry(lun: u8, vendor_id: *[8]u8, product_id: *[16]u8, product_rev: *[4]u8) void {
        _ = lun;
        const vid = "Ztusb";
        const pid = "Mass Storage";
        const rev = "1.0";

        @memcpy(vendor_id[0..vid.len], vid);
        @memcpy(product_id[0..pid.len], pid);
        @memcpy(product_rev[0..rev.len], rev);
    }

    pub fn test_unit_ready(lun: u8) bool {
        if (ejected) {
            return MSC_Device.set_sense(lun, 2, 0x3a, 0x00);
        }

        return true;
    }

    pub fn capacity(lun: u8, block_count: *u32, block_size: *u16) void {
        _ = lun;

        block_count.* = DISK_BLOCK_NUM;
        block_size.* = DISK_BLOCK_SIZE;
    }

    pub fn start_stop(lun: u8, power_condition: u8, start: bool, load_eject: bool) bool {
        _ = lun;
        _ = power_condition;

        if (load_eject) {
            if (start) {} else {
                ejected = true;
            }
        }

        return true;
    }

    pub fn read10(lun: u8, lba: u32, off: u32, buf: []u8) i32 {
        _ = lun;

        // out of ramdisk
        if (lba >= DISK_BLOCK_NUM) {
            return -1;
        }

        // Check for overflow of offset + bufsize
        if (((lba * DISK_BLOCK_SIZE) + off + buf.len) > (DISK_BLOCK_NUM * DISK_BLOCK_SIZE)) {
            return -1;
        }

        const addr: [*]const u8 = @as([*]const u8, @ptrCast(&msc_disk[lba])) + off;
        @memcpy(buf, addr[0..buf.len]);

        return @intCast(buf.len);
    }

    pub fn write10(lun: u8, lba: u32, offset: u32, buffer: [*]const u8, bufsize: u32) i32 {
        _ = lun;

        // out of ramdisk
        if (lba >= DISK_BLOCK_NUM) {
            return -1;
        }

        _ = offset;
        _ = buffer;

        return @intCast(bufsize);
    }

    pub fn scsi(lun: u8, scsi_cmd: *const [16]u8, buffer: ?*anyopaque, bufsize: u16) i32 {
        _ = scsi_cmd;
        _ = buffer;
        _ = bufsize;

        // currently no other commands are supported

        // Set Sense = Invalid Command Operation
        _ = MSC_Device.set_sense(lun, 5, 0x20, 0x00);

        return -1; // stall/failed command request;
    }
};
