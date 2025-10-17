# Portable Embedded Build System for Seeed XIAO M0+ (SAMD21)

## Project Goal

This repository provides a prototype of a customized and **build system** using a **GNU Makefile** to compile C/C++ projects for the **Seeed XIAO** (Microchip SAMD21) mcu hardware.

This approach bypasses the Arduino IDE to achieve complete control over the toolchain, essential for **rtw** integration, advanced port monitoring, and establishing a professional, repeatable application build process. This makefile sets the template to integrate tools for code generation software.

## Few Technical Details of Intended Platform

| Component | Specification/Source | Notes |
| :--- | :--- | :--- |
| **Target MCU** | **Microchip SAMD21G18A** (on Seeed XIAO M0) | Cortex-M0+ core, running at 48MHz (F\_CPU=48000000L). |
| **Toolchain** | **Arm GNU Embedded Toolchain 7-2017q4** | The specific cross-compiler used for `arm-none-eabi-*` binaries. |
| **Core Dependency** | **ArduinoCore-samd-master** (Local Copy Required) | Provides the core startup files, device header files, and linker script (`flash_with_bootloader.ld`). |
| **Integrated Libraries** | `TimerTC3`, `Adafruit_TinyUSB` | Libraries included in the core build process to enable timer interrupts and native USB functionality. |
| **Compiler Flags** | `-mcpu=cortex-m0plus`, `-mthumb`, `-Os`, `-nostdlib`, `-Wl,--gc-sections` | Flags are highly optimized for size and embedded architecture. |
| **Flashing Tool** | **BOSSAC v1.7.0** (Windows-specific) | The upload target uses Windows `mode` and `powershell` commands to trigger the bootloader and flash the `.bin` file via COM port. |

## Prerequisites

1.  **Arm GNU Toolchain:** The specific version (7-2017q4 or compatible) must be installed.
2.  **Arduino Core Files:** A local, cloned copy of the [ArduinoCore-samd-master](https://github.com/arduino/ArduinoCore-samd) repository is required to resolve all include paths (must be referenced by the `CORE_PATH` variable).
3.  **GNU Make:** Version 4.0+ is recommended.

## Usage

1.  **Configure Paths:** Create a `config.mk` file (based on the provided template) in the root directory and define the local paths for `TOOLCHAIN_PATH`, `CORE_PATH`, `SERIAL_PORT`, and `BOOTLOADER_PORT`.
2.  **Build:**
    ```bash
    make build
    ```
3.  **Clean:**
    ```bash
    make clean
    ```
4.  **Flash (Windows Only):**
    ```bash
    make upload
    ```
