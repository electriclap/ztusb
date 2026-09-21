#include "tusb.h"
#include "tusb_shim.h"


uint32_t SystemCoreClock = 16000000;



void usb_init(void) {
    tusb_rhport_init_t dev_init = {
        .role  = TUSB_ROLE_DEVICE,
        .speed = TUSB_SPEED_FULL,
    };
    tusb_init(0, &dev_init);
}

void usb_set_system_core_clock(uint32_t system_core_clock) {SystemCoreClock = system_core_clock;}


void usb_task(void) { tud_task(); }
void usb_irq(void)  { tud_int_handler(0); }


bool     usb_cdc_connected(void) { return tud_cdc_connected(); }
uint32_t usb_cdc_available(void) { return tud_cdc_available(); }
uint32_t usb_cdc_read(uint8_t *buf, uint32_t len)        { return tud_cdc_read(buf, len); }
uint32_t usb_cdc_write(const uint8_t *buf, uint32_t len) { return tud_cdc_write(buf, len); }
void     usb_cdc_flush(void) { (void)tud_cdc_write_flush(); }