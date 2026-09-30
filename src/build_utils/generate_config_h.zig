const std = @import("std");
const TusbDriver = @import("../../build.zig").TusbDriver;
const TusbConfig = @import("../../build.zig").TusbConfig;

const CONFIG_DESC_LEN: u32 = 9;
const DEVICE_CDC_DESC_LEN: u32 = 66;
const DEVICE_MSC_DESC_LEN: u32 = 23;
const DEVICE_MIDI_DESC_LEN: u32 = 92;

const ENDPOINT_INPUT_BITMASK: u32 = 0x80;

pub fn create_tusb_config_header(b: *std.Build, config: TusbConfig) *std.Build.Step.ConfigHeader {
    const header = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "tusb_config.h",
    }, .{});

    // Tusb config header defines
    header.addIdent("CFG_TUSB_MCU", config.mcu);
    header.addIdent("CFG_TUSB_OS", config.os);
    header.addValue("CFG_TUSB_DEBUG", u8, config.debug);

    header.addValue("CFG_TUD_ENABLED", bool, config.device);
    header.addValue("CFG_TUH_ENABLED", bool, config.host);

    header.addIdent("CFG_TUD_MAX_SPEED", config.device_max_speed);
    header.addIdent("CFG_TUH_MAX_SPEED", config.host_max_speed);

    var formatted_mem_section: []const u8 = "";
    if (config.mem_section.len > 0) {
        formatted_mem_section = b.allocator.print("__attribute__((section(\"{s}\")))", .{config.mem_section}) catch @panic("OOM");
    }
    header.addIdent("CFG_TUSB_MEM_SECTION", formatted_mem_section);

    const formatted_mem_align: []const u8 = b.allocator.print("__attribute__ ((aligned({d})))", .{config.mem_alignment}) catch @panic("OOM");
    header.addIdent("CFG_TUSB_MEM_ALIGN", formatted_mem_align);

    header.addValue("CFG_TUD_ENDPOINT0_SIZE", u32, config.endpoint0_size);

    header.addValue("CFG_TUD_CDC", bool, config.cdc_device);
    header.addValue("CFG_TUD_MSC", bool, config.msc_device);
    header.addValue("CFG_TUD_HID", bool, config.hid_device);
    header.addValue("CFG_TUD_MIDI", bool, config.midi_device);

    header.addValue("CFG_TUD_CDC_RX_BUFSIZE", u32, config.cdc_rx_bufsize);
    header.addValue("CFG_TUD_CDC_TX_BUFSIZE", u32, config.cdc_tx_bufsize);
    header.addValue("CFG_TUD_CDC_RX_EPSIZE", u32, config.cdc_rx_epsize);
    header.addValue("CFG_TUD_CDC_TX_EPSIZE", u32, config.cdc_tx_epsize);

    header.addValue("CFG_TUD_MSC_EP_BUFSIZE", u32, config.msc_ep_bufsize);

    header.addValue("CFG_TUD_MIDI_RX_BUFSIZE", u32, config.midi_rx_bufsize);
    header.addValue("CFG_TUD_MIDI_TX_BUFSIZE", u32, config.midi_tx_bufsize);

    // usb descriptors defines
    var total_len: u32 = CONFIG_DESC_LEN;
    var endpoint_index: u32 = 1;
    if (config.cdc_device) {
        total_len += DEVICE_CDC_DESC_LEN;
        header.addValue("EPNUM_CDC_NOTIF", u32, (ENDPOINT_INPUT_BITMASK | endpoint_index));
        endpoint_index += 1;
        header.addValue("EPNUM_CDC_OUT", u32, (endpoint_index));
        header.addValue("EPNUM_CDC_IN", u32, (ENDPOINT_INPUT_BITMASK | endpoint_index));
        endpoint_index += 1;
    }

    if (config.msc_device) {
        total_len += DEVICE_MSC_DESC_LEN;
        header.addValue("EPNUM_MSC_OUT", u32, (endpoint_index));
        header.addValue("EPNUM_MSC_IN", u32, (ENDPOINT_INPUT_BITMASK | endpoint_index));
        endpoint_index += 1;
    }

    if (config.midi_device) {
        total_len += DEVICE_MIDI_DESC_LEN;
        header.addValue("EPNUM_MIDI_OUT", u32, (endpoint_index));
        header.addValue("EPNUM_MIDI_IN", u32, (ENDPOINT_INPUT_BITMASK | endpoint_index));
        endpoint_index += 1;
    }

    header.addValue("CONFIG_TOTAL_LEN", u32, total_len); // we move this define in the config header to simplify usb_descriptors.c file gen

    return header;
}
