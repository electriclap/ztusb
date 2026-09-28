pub const TusbDriver = enum {
    dwc2,
    fsdev,
    rp2040,
    pio_usb,
};

pub const TusbConfig = struct {
    pid: u16 = 0x4001,
    vid: u16 = 0xcafe,
    bcd: u16 = 0x0200,
    id: []const u8 = "000000000001",

    mcu: []const u8 = "OPT_MCU_STM32F4",
    os: []const u8 = "OPT_OS_NONE",
    debug: u8 = 0,

    device: bool = false,
    host: bool = false,
    device_max_speed: []const u8 = "OPT_MODE_FULL_SPEED",
    host_max_speed: []const u8 = "OPT_MODE_FULL_SPEED",

    mem_section: []const u8 = "",
    mem_alignment: u32 = 4,

    endpoint0_size: u32 = 64,

    cdc_device: bool = false,
    msc_device: bool = false,
    hid_device: bool = false,
    midi_device: bool = false,

    cdc_notify: bool = true,
    cdc_rx_bufsize: u32 = 64,
    cdc_tx_bufsize: u32 = 64,
    cdc_rx_epsize: u32 = 64,
    cdc_tx_epsize: u32 = 64,

    midi_rx_bufsize: u32 = 64,
    midi_tx_bufsize: u32 = 64,

    msc_ep_bufsize: u32 = 512,
};
