const bridge = @import("tusb_bridge");

// TODO create a midi packet type
pub const MIDI_Device = struct {
    pub fn is_mounted() bool {
        return bridge.usbd_midi_mounted();
    }

    pub fn is_available() u32 {
        return bridge.usbd_midi_available();
    }

    // TODO find a way to drop ?*anyopaque
    pub fn stream_read(buffer: ?*anyopaque, size: u32) u32 {
        return bridge.usbd_midi_stream_read(buffer, size);
    }

    // TODO find a way to drop ?*anyopaque
    pub fn demux_stream_read(cable_num: *u8, buffer: ?*anyopaque, size: u32) u32 {
        return bridge.usbd_midi_demux_stream_read(cable_num, buffer, size);
    }

    pub fn stream_write(cable_num: u8, buffer: []const u8) u32 {
        return bridge.usbd_midi_stream_write(cable_num, buffer.ptr, buffer.len);
    }

    pub fn packet_read(packet: *[4]u8) bool {
        return bridge.usbd_midi_packet_read(packet[0..4]);
    }

    pub fn packet_read_n(packets: [][4]u8) u32 {
        return bridge.usbd_midi_packet_read_n(packets.ptr, packets.len);
    }

    pub fn packet_write(packet: *const [4]u8) bool {
        return bridge.usbd_midi_packet_write(packet);
    }

    pub fn packet_write_n(packets: []const [4]u8) u32 {
        return bridge.usbd_midi_packet_write_n(packets.ptr, packets.len);
    }
};
