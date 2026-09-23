#pragma once
#include <stdint.h>
#include <stdbool.h>

typedef enum {
    USB_ROLE_INVALID = 0,
    USB_ROLE_DEVICE = 1,
    USB_ROLE_HOST = 2,
} usb_role_t;

typedef enum {
  USB_SPEED_FULL = 0,
  USB_SPEED_LOW  = 1,
  USB_SPEED_HIGH = 2,
  USB_SPEED_AUTO = 0xaa,
  USB_SPEED_INVALID = 0xff,
} usb_speed_t;

void usb_init(uint8_t port, usb_role_t role, usb_speed_t speed, uint32_t system_core_clock);

void usbd_task(void);
void usbd_irq(uint8_t port);

void usbh_task(void);
void usbh_irq(uint8_t port);

bool     usbd_cdc_isconnected(void);
uint32_t usbd_cdc_available(void);
uint32_t usbd_cdc_read(uint8_t *buf, uint32_t len);
uint32_t usbd_cdc_write(const uint8_t *buf, uint32_t len);
void     usbd_cdc_write_flush(void);
void     usbd_cdc_read_flush(void);