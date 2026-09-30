#pragma once
#include <stdint.h>
#include <stdbool.h>

typedef enum {
  USB_SPEED_FULL = 0,
  USB_SPEED_LOW  = 1,
  USB_SPEED_HIGH = 2,
  USB_SPEED_AUTO = 0xaa,
  USB_SPEED_INVALID = 0xff,
} usb_speed_t;

// Device
void usbd_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock);
bool usbd_inited(void);
void usbd_irq(uint8_t port);
void usbd_task(void);
bool usbd_is_connected(void);
bool usbd_is_mounted(void);
bool usbd_is_suspended(void);
bool usbd_is_ready(void);

// Host
void usbh_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock);
bool usbh_inited(void);
void usbh_task(void);
void usbh_irq(uint8_t port);

// CDC Device
bool     usbd_cdc_is_ready(void);
bool     usbd_cdc_is_connected(void);
uint32_t usbd_cdc_get_available_bytes(void);
uint32_t usbd_cdc_read(uint8_t *buf, uint32_t len);
int32_t  usbd_cdc_read_char(void);
void     usbd_cdc_read_flush(void);
uint32_t usbd_cdc_write(const uint8_t *buf, uint32_t len);
uint32_t usbd_cdc_write_char(char ch);
void     usbd_cdc_write_flush(void);

// MSC Device
bool     usbd_msc_set_sense(uint8_t lun, uint8_t sense_key, uint8_t add_sense_code, uint8_t add_sense_qualifier);
bool     usbd_msc_async_io_done(int32_t bytes_io, bool in_isr);


// MIDI Device
bool     usbd_midi_mounted(void);
uint32_t usbd_midi_available(void);
uint32_t usbd_midi_stream_read(void *buffer, uint32_t bufsize);
uint32_t usbd_midi_demux_stream_read(uint8_t *p_cable_num, void *buffer, uint32_t bufsize);
uint32_t usbd_midi_stream_write(uint8_t cable_num, const uint8_t *buffer, uint32_t bufsize);
bool     usbd_midi_packet_read(uint8_t packet[4]);
uint32_t usbd_midi_packet_read_n(uint8_t packets[], uint32_t max_packets);
bool     usbd_midi_packet_write(const uint8_t packet[4]);
uint32_t usbd_midi_packet_write_n(const uint8_t packets[], uint32_t n_packets);
