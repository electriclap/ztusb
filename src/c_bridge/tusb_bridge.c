#include "tusb.h"
#include "tusb_bridge.h"


// this global is needed is St's dependencies.
uint32_t SystemCoreClock = 16000000;


/*** Usb device API ***/
#if CFG_TUD_ENABLED
void usbd_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock) {
    
    SystemCoreClock = system_core_clock;
    
    if (port > 1) {
        port = 0;
    }
    
    tusb_rhport_init_t dev_init = {
        .role  = TUSB_ROLE_DEVICE,
        .speed = (tusb_speed_t)speed,
    };
    tusb_init(port, &dev_init);
}

bool usbd_inited(void){
    return tud_inited();
}

void usbd_irq(uint8_t port) { 
    tud_int_handler(port); 
}

void usbd_task(void) { 
    tud_task(); 
}

bool usbd_is_connected(void){
    return tud_connected();
}

bool usbd_is_mounted(void){
    return tud_mounted();
}

bool usbd_is_suspended(void){
    return tud_suspended();
}

bool usbd_is_ready(void){
    return tud_ready();
}
#endif

/*** USB Host API ***/
#if CFG_TUH_ENABLED
void usbh_init(uint8_t port, usb_speed_t speed, uint32_t system_core_clock) {
    
    SystemCoreClock = system_core_clock;
    
    if (port > 1) {
        port = 0;
    }
    
    tusb_rhport_init_t dev_init = {
        .role  = TUSB_ROLE_HOST,
        .speed = (tusb_speed_t)speed,
    };
    tusb_init(port, &dev_init);
}

bool usbh_inited(void){
    tuh_inited();
}

void usbh_irq(uint8_t port) { 
    tuh_int_handler(port); 
}

void usbh_task(void) { 
    tuh_task(); 
}
#endif

/*** USB CDC device API ***/
#if CFG_TUD_ENABLED && CFG_TUD_CDC

bool usbd_cdc_is_ready(void) {
    return tud_cdc_ready();
}

bool usbd_cdc_is_connected(void) {
    return tud_cdc_connected(); 
}

uint32_t usbd_cdc_get_available_bytes(void) {
    return tud_cdc_available(); 
}

uint32_t usbd_cdc_read(uint8_t *buf, uint32_t len) {
    return tud_cdc_read(buf, len);
}

int32_t usbd_cdc_read_char(void) {
    return tud_cdc_read_char();
}

void usbd_cdc_read_flush(void) {
    (void)tud_cdc_read_flush();
}

uint32_t usbd_cdc_write(const uint8_t *buf, uint32_t len) {
    return tud_cdc_write(buf, len);
}

uint32_t usbd_cdc_write_char(char ch) {
    return tud_cdc_write_char(ch);
}

void usbd_cdc_write_flush(void) {
    (void)tud_cdc_write_flush();
}
#endif

#if CFG_TUD_ENABLED && CFG_TUD_MSC
bool usbd_msc_set_sense(uint8_t lun, uint8_t sense_key, uint8_t add_sense_code, uint8_t add_sense_qualifier) {
    return tud_msc_set_sense(lun, sense_key, add_sense_code, add_sense_qualifier);
}

bool usbd_msc_async_io_done(int32_t bytes_io, bool in_isr) {
    return tud_msc_async_io_done(bytes_io, in_isr);
}
#endif


/* USB MIDI device API */
#if CFG_TUD_ENABLED && CFG_TUD_MIDI
bool usbd_midi_mounted(void) {
    return tud_midi_mounted();
}

uint32_t usbd_midi_available(void) {
    return tud_midi_available();
}

uint32_t usbd_midi_stream_read(void *buffer, uint32_t bufsize) {
    return tud_midi_stream_read(buffer, bufsize);
}

uint32_t usbd_midi_demux_stream_read(uint8_t *p_cable_num, void *buffer, uint32_t bufsize) {
    return tud_midi_demux_stream_read(p_cable_num, buffer, bufsize);
}

uint32_t usbd_midi_stream_write(uint8_t cable_num, const uint8_t *buffer, uint32_t bufsize) {
    return tud_midi_stream_write(cable_num, buffer, bufsize);
}

bool usbd_midi_packet_read(uint8_t packet[4]) {
    return tud_midi_packet_read(packet);
}

uint32_t usbd_midi_packet_read_n(uint8_t packets[], uint32_t max_packets) {
    return tud_midi_packet_read_n(packets, max_packets);
}

bool usbd_midi_packet_write(const uint8_t packet[4]) {
    return tud_midi_packet_write(packet);
}

uint32_t usbd_midi_packet_write_n(const uint8_t packets[], uint32_t n_packets) {
    return tud_midi_packet_write_n(packets, n_packets);
}
#endif


/* usb host cdc shimed API */
// TODO

/* usb host midi shimed API */
// TODO


