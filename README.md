# ztusb
A zig wrapper for tiny usb. Intended to be used alongside micro zig.


## Support

- tusb_config.h autogen at build
- usb_descriptors.c autogen at build
- usb full speed
- cdc device
- msc device

## TODO

- all drivers support
- all mcus support
- more class support

## How to use

fetch with 
```zig
zig fetch --save TODO
``` 

If you need external dependencies, fetch them also. tinyusb wiki lists all possible dependencies and where to find them :

https://docs.tinyusb.org/en/latest/reference/dependencies.html

for exemple, for my stm32f407 : 

```zig
zig fetch --save=cmsis_device_f4 ""
```

Then, add these following lines to your microzig project build.zig (cdc device example) : 

```zig
    const target = firmware.exe.root_module.resolved_target.?;

    const ztusb_config = b.dependency("ztusb", .{
        .target = target,
        .optimize = optimize,
        .driver = .dwc2,  // check out tinu usb repo for choosing the right driver for your mcu
        .device = true,
        .cdc = true,
    });
    const ztusb = ztusb_config.module("ztusb");

    // This part is optional and depends on your MCU (STM32F407 example)
    // see https://docs.tinyusb.org/en/latest/reference/dependencies.html
    const cmsis_stm32_dep = b.dependency("cmsis_device_f4", .{});
    ztusb.addIncludePath(cmsis_stm32_dep.path("Include"));
    ztusb.addCMacro("STM32F407xx", "1");

    ztusb.addCSourceFile(.{
        .file = b.path("path/to/your/usb_descriptors.c"),  // 
        .flags = &.{},
    });

    firmware.exe.root_module.addImport("ztusb", ztusb);
```