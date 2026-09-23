# ztusb
A zig wrapper for tiny usb


## How to use

1. fetch this package with 
```zig
zig fetch --save TODO
``` 

2. If you need external dependencies, fetch them also. tinyusb wiki lists all possible dependencies and where to find them :

https://docs.tinyusb.org/en/latest/reference/dependencies.html

for exemple, for my stm32f407 : 

```zig
zig fetch --save=cmsis_

3. Add these following lines to your build.zig (cdc device example) : 

```zig
    const target = firmware.exe.root_module.resolved_target.?;

    const ztusb_config = b.dependency("ztusb", .{
        .target = target,
        .optimize = optimize,
        .driver = .dwc2,  // select the right usb driver for your MCU
        .cdc = true,
        .midi = false,
    });
    const ztusb = ztusb_config.module("ztusb");

    // This part is optional and depends on your MCU (STM32F407 example)
    // consult https://docs.tinyusb.org/en/latest/reference/dependencies.html
    const cmsis_stm32_dep = b.dependency("cmsis_device_f4", .{});
    ztusb.addIncludePath(cmsis_stm32_dep.path("Include"));
    ztusb.addCMacro("STM32F407xx", "1");

    ztusb.addIncludePath(b.path("path/to/your/tusb/folder/containing/tusb_config.h"));
    ztusb.addCSourceFile(.{
        .file = b.path("path/to/your/usb_descriptors.c"),  // 
        .flags = &.{},
    });

    firmware.exe.root_module.addImport("ztusb", ztusb);
```