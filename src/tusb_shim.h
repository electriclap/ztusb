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

void usbd_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock);
bool usbd_inited(void);
void usbd_irq(uint8_t port);
void usbd_task(void);
bool usbd_is_connected(void);
bool usbd_is_mounted(void);
bool usbd_is_suspended(void);
bool usbd_is_ready(void);

void usbh_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock);
bool usbh_inited(void);
void usbh_task(void);
void usbh_irq(uint8_t port);

bool     usbd_cdc_is_ready(void);
bool     usbd_cdc_is_connected(void);
uint32_t usbd_cdc_get_available_bytes(void);
uint32_t usbd_cdc_read(uint8_t *buf, uint32_t len);
int32_t  usbd_cdc_read_char(void);
void     usbd_cdc_read_flush(void);
uint32_t usbd_cdc_write(const uint8_t *buf, uint32_t len);
uint32_t usbd_cdc_write_char(char ch);
void     usbd_cdc_write_flush(void);
