// ---- TinyUSB helper we call from the defaults ----
extern fn tud_msc_set_sense(lun: u8, sense_key: u8, asc: u8, ascq: u8) bool;

const SENSE_NOT_READY: u8 = 0x02;
const SENSE_ILLEGAL_REQUEST: u8 = 0x05;

pub const InquiryFn = *const fn (lun: u8, vendor_id: *[8]u8, product_id: *[16]u8, product_rev: *[4]u8) void;
pub const TestUnitReadyFn = *const fn (lun: u8) bool;
pub const CapacityFn = *const fn (lun: u8, block_count: *u32, block_size: *u16) void;
pub const StartStopFn = *const fn (lun: u8, power_condition: u8, start: bool, load_eject: bool) bool;
pub const Read10Fn = *const fn (lun: u8, lba: u32, offset: u32, buffer: [*]u8, bufsize: u32) i32;
pub const Write10Fn = *const fn (lun: u8, lba: u32, offset: u32, buffer: [*]const u8, bufsize: u32) i32;
pub const ScsiFn = *const fn (lun: u8, scsi_cmd: *const [16]u8, buffer: ?*anyopaque, bufsize: u16) i32;

// Default callbacks
fn dummyInquiry(_: u8, _: *[8]u8, _: *[16]u8, _: *[4]u8) void {}

fn dummyTestUnitReady(lun: u8) bool {
    _ = tud_msc_set_sense(lun, SENSE_NOT_READY, 0x3A, 0x00); // medium not present
    return false;
}

fn dummyCapacity(_: u8, block_count: *u32, block_size: *u16) void {
    block_count.* = 0;
    block_size.* = 512; // never leave 0
}

fn dummyStartStop(_: u8, _: u8, _: bool, _: bool) bool {
    return true;
}

fn dummyRead10(lun: u8, _: u32, _: u32, _: [*]u8, _: u32) i32 {
    _ = tud_msc_set_sense(lun, SENSE_NOT_READY, 0x3A, 0x00);
    return -1;
}

fn dummyWrite10(lun: u8, _: u32, _: u32, _: [*]const u8, _: u32) i32 {
    _ = tud_msc_set_sense(lun, SENSE_NOT_READY, 0x3A, 0x00);
    return -1;
}

fn dummyScsi(lun: u8, _: *const [16]u8, _: ?*anyopaque, _: u16) i32 {
    _ = tud_msc_set_sense(lun, SENSE_ILLEGAL_REQUEST, 0x20, 0x00); // invalid command
    return -1;
}

// ---- Current handlers ----
const Handlers = struct {
    inquiry: InquiryFn = dummyInquiry,
    test_unit_ready: TestUnitReadyFn = dummyTestUnitReady,
    capacity: CapacityFn = dummyCapacity,
    start_stop: StartStopFn = dummyStartStop,
    read10: Read10Fn = dummyRead10,
    write10: Write10Fn = dummyWrite10,
    scsi: ScsiFn = dummyScsi,
};

var handlers: Handlers = .{};

pub fn setInquiry(f: InquiryFn) void {
    handlers.inquiry = f;
}
pub fn setTestUnitReady(f: TestUnitReadyFn) void {
    handlers.test_unit_ready = f;
}
pub fn setCapacity(f: CapacityFn) void {
    handlers.capacity = f;
}
pub fn setStartStop(f: StartStopFn) void {
    handlers.start_stop = f;
}
pub fn setRead10(f: Read10Fn) void {
    handlers.read10 = f;
}
pub fn setWrite10(f: Write10Fn) void {
    handlers.write10 = f;
}
pub fn setScsi(f: ScsiFn) void {
    handlers.scsi = f;
}

/// Restore every callback to its dummy default.
pub fn resetDefaults() void {
    handlers = .{};
}

// ---- Exported symbols TinyUSB links against ----
export fn tud_msc_inquiry_cb(lun: u8, vendor_id: *[8]u8, product_id: *[16]u8, product_rev: *[4]u8) callconv(.c) void {
    handlers.inquiry(lun, vendor_id, product_id, product_rev);
}

export fn tud_msc_test_unit_ready_cb(lun: u8) callconv(.c) bool {
    return handlers.test_unit_ready(lun);
}

export fn tud_msc_capacity_cb(lun: u8, block_count: *u32, block_size: *u16) callconv(.c) void {
    handlers.capacity(lun, block_count, block_size);
}

export fn tud_msc_start_stop_cb(lun: u8, power_condition: u8, start: bool, load_eject: bool) callconv(.c) bool {
    return handlers.start_stop(lun, power_condition, start, load_eject);
}

export fn tud_msc_read10_cb(lun: u8, lba: u32, offset: u32, buffer: [*]u8, bufsize: u32) callconv(.c) i32 {
    return handlers.read10(lun, lba, offset, buffer, bufsize);
}

export fn tud_msc_write10_cb(lun: u8, lba: u32, offset: u32, buffer: [*]const u8, bufsize: u32) callconv(.c) i32 {
    return handlers.write10(lun, lba, offset, buffer, bufsize);
}

export fn tud_msc_scsi_cb(lun: u8, scsi_cmd: *const [16]u8, buffer: ?*anyopaque, bufsize: u16) callconv(.c) i32 {
    return handlers.scsi(lun, scsi_cmd, buffer, bufsize);
}
