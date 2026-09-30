# ztusb
A zig wrapper for tiny usb. Intended to be used with microzig.\
Microzig repo : https://github.com/ZigEmbeddedGroup/microzig

## Support

- tusb_config.h and usb_descriptors.c autogen from build options
- usb device full speed
- cdc device
- msc device
- midi device

## Next

- vtable for runtime switching callbacks
- host support
- audio and mtp classes support

## How to use

fetch with 
```zig
zig fetch --save 'git+https://github.com/electriclap/ztusb?ref=main'
``` 

If you need external dependencies, fetch them also. tinyusb wiki lists all possible dependencies and where to find them:\
https://docs.tinyusb.org/en/latest/reference/dependencies.html

example, for a stm32f407 : 

```zig
zig fetch --save=cmsis_device_f4 'git+https://github.com/STMicroelectronics/cmsis_device_f4'
```

Then, add these following lines to your microzig project build.zig (cdc+msc device example) : 

```zig
    const ztusb_config = b.dependency("ztusb", .{
        .target = firmware.exe.root_module.resolved_target,
        .optimize = optimize,
        .driver = .dwc2,  // check out tiny usb repo for choosing the right driver for your mcu
        .device = true,
        .cdc_device = true,
        .msc_device = true,
    });
    const ztusb = ztusb_config.module("ztusb");

    // OPTIONAL PART //
    const cmsis_stm32_dep = b.dependency("cmsis_device_f4", .{});
    ztusb.addIncludePath(cmsis_stm32_dep.path("Include"));
    ztusb.addCMacro("STM32F407xx", "1");
    // END OPTIONAL PART // 

    firmware.exe.root_module.addImport("ztusb", ztusb);
```

In this main.zig example, you should see a VCOM and a Mass storage device. The Mass storage device will be named "Ztusb MSC" and contain a small readme.txt file. Also, sending a char to the device will echo it and write "Message Received!" :

```zig

const std = @import("std");
const microzig = @import("microzig");
const ztusb = @import("ztusb");

pub const panic = microzig.panic;
pub const std_options = microzig.std_options(.{});

comptime {
    _ = microzig.export_startup();
}

pub const microzig_options: microzig.Options = .{
    .interrupts = .{
        .SysTick = .{ .c = systick.SysTick_Handler },
        .OTG_FS = .{ .c = OTG_FS_handler },
    },
};

pub fn main() !void {
    microzig.interrupt.enable(.OTG_FS);
    microzig.interrupt.enable_interrupts();

    // your low level init
    rcc.init();
    systick.init();
    gpio.init();

    // don't forget to configure your GPIO pins and RCC for USB, Tiny USB doesn't do that for you.

    ztusb.set_millis_callback(systick.get_tick);
    ztusb.Device.init(.PORT0, .USB_SPEED_FULL, 168_000_000);

    while (true) {
        ztusb.Device.task();

        const char: i32 = ztusb.CDC_Device.read_char();
        if (char >= 0) {
            _ = ztusb.CDC_Device.write_char(@as(u8, @intCast(char)));
        }
    }
}

// export callbacks methods need to be in a comptime block
comptime {
    ztusb.CDC_Device.export_callbacks(CDC_DeviceCallbacks);
    ztusb.MSC_Device.export_callbacks(ztusb.MSC_TestDisk);
}

const CDC_DeviceCallbacks = struct {
    pub fn on_rx(_: u8) void {
        _ = ztusb.CDC_Device.write("Message received!\r\n");
        ztusb.CDC_Device.write_flush();
    }
};

pub fn OTG_FS_handler() callconv(.c) void {
    ztusb.Device.irq(.PORT0);
}
```