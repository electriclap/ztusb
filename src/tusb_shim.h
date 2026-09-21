#pragma once
#include <stdint.h>
#include <stdbool.h>


void     usb_init(void);
void     usb_task(void);
void     usb_irq(void);

void     usb_set_system_core_clock(uint32_t system_core_clock);

bool     usb_cdc_connected(void);
uint32_t usb_cdc_available(void);
uint32_t usb_cdc_read(uint8_t *buf, uint32_t len);
uint32_t usb_cdc_write(const uint8_t *buf, uint32_t len);
void     usb_cdc_flush(void);