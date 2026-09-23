#include "tusb.h"
#include "tusb_shim.h"


// this global is needed is St's dependencies.
uint32_t SystemCoreClock = 16000000;


void usb_init(uint32_t port, usb_role_t role, usb_speed_t speed, uint32_t system_core_clock) {
    
    SystemCoreClock = system_core_clock;
    
    if (port > 1) {
        port = 0;
    }
    
    tusb_rhport_init_t dev_init = {
        .role  = (tusb_role_t)role,
        .speed = (tusb_speed_t)speed,
    };
    tusb_init(port, &dev_init);
}

void usbd_irq(uint32_t port) { 
    tud_int_handler(port); 
}

void usbh_irq(uint32_t port) { 
    tuh_int_handler(port); 
}

#if CFG_TUD_ENABLED
void usbd_task(void) { 
    tud_task(); 
}
#endif

#if CFG_TUH_ENABLED
void usbh_task(void) { 
    tuh_task(); 
}
#endif

/*** usb device cdc shimed API ***/
#if CFG_TUD_ENABLED && CFG_TUD_CDC
bool usbd_cdc_isconnected(void) {
    return tud_cdc_connected(); 
}

uint32_t usbd_cdc_available(void) {
    return tud_cdc_available(); 
}

uint32_t usbd_cdc_read(uint8_t *buf, uint32_t len) {
    return tud_cdc_read(buf, len);
}

uint32_t usbd_cdc_write(const uint8_t *buf, uint32_t len) {
    return tud_cdc_write(buf, len);
}

void usbd_cdc_write_flush(void) {
    (void)tud_cdc_write_flush();
}

void usbd_cdc_read_flush(void) {
    (void)tud_cdc_read_flush();
}
#endif


/* usb host cdc shimed API */
// TODO


/* usb device midi shimed API */
// TODO


/* usb host midi shimed API */
// TODO


