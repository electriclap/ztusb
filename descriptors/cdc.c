#include <string.h>
#include "tusb.h"

#define USB_VID 0xCafe
#define USB_PID 0x4001

static tusb_desc_device_t const desc_device = {
    .bLength            = sizeof(tusb_desc_device_t),
    .bDescriptorType    = TUSB_DESC_DEVICE,
    .bcdUSB             = 0x0200,
    .bDeviceClass       = TUSB_CLASS_MISC,
    .bDeviceSubClass    = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol    = MISC_PROTOCOL_IAD,
    .bMaxPacketSize0    = CFG_TUD_ENDPOINT0_SIZE,
    .idVendor           = USB_VID,
    .idProduct          = USB_PID,
    .bcdDevice          = 0x0100,
    .iManufacturer      = 1,
    .iProduct           = 2,
    .iSerialNumber      = 3,
    .bNumConfigurations = 1,
};

uint8_t const *tud_descriptor_device_cb(void) {
    return (uint8_t const *)&desc_device;
}

enum { ITF_NUM_CDC = 0, ITF_NUM_CDC_DATA, ITF_NUM_TOTAL };
#define CONFIG_TOTAL_LEN (TUD_CONFIG_DESC_LEN + TUD_CDC_DESC_LEN)

static uint8_t const desc_configuration[] = {
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),
    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, 4, 0x81, 8, 0x02, 0x82, 64),
};

uint8_t const *tud_descriptor_configuration_cb(uint8_t index) {
    (void)index;
    return desc_configuration;
}

static char const *string_desc[] = {
    (char[]){0x09, 0x04}, // 0: English (US)
    "zsynth",             // 1: manufacturer
    "zsynth CDC",         // 2: product
    "000001",             // 3: serial
    "zsynth CDC",         // 4: CDC interface
};

static uint16_t desc_str[32 + 1];

uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid) {
    (void)langid;
    uint8_t n;
    if (index == 0) {
        memcpy(&desc_str[1], string_desc[0], 2);
        n = 1;
    } else {
        if (index >= sizeof(string_desc) / sizeof(string_desc[0])) return NULL;
        const char *s = string_desc[index];
        n = (uint8_t)strlen(s);
        if (n > 31) n = 31;
        for (uint8_t i = 0; i < n; i++) desc_str[1 + i] = s[i];
    }
    desc_str[0] = (uint16_t)((TUSB_DESC_STRING << 8) | (2 * n + 2));
    return desc_str;
}