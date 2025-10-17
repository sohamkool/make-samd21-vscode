# ===============================================================================
# Generalized Embedded Build System for Arm MCU (Seeed XIAO M0/SAMD21)
#
# This Makefile automates the complex multi-stage compilation and linking of
# a sketch, core files, and libraries (CMSIS, TimerTC3, TinyUSB) using the
# Arm cross-toolchain. It is designed to be portable across user installations.
#
# USAGE: make [all | clean | upload]
#
# All absolute paths must be defined in 'config.mk' or environment variables.
# ===============================================================================

# -------------------------------------------------------------------------------
# 1. PATH CONFIGURATION & LOCAL OVERRIDE (PORTABILITY)
# -------------------------------------------------------------------------------

# Load machine-specific paths (e.g., TOOLCHAIN_PATH, CORE_PATH) from config.mk
-include config.mk

# --- Base Toolchain & Paths (Defaults to empty if not set externally) ---
TOOLCHAIN_PATH ?=
CORE_PATH ?=
SERIAL_PORT ?= COM4    # Default COM port for Windows systems
BOOTLOADER_PORT ?= COM5

PREFIX := $(TOOLCHAIN_PATH)arm-none-eabi-

# Core Tools
CC      := $(PREFIX)gcc
CXX     := $(PREFIX)g++
OBJCOPY := $(PREFIX)objcopy
SIZE    := $(PREFIX)size
# NOTE: BOSSAC tool path is derived from CORE_PATH, assuming standard structure.
BOSSAC_TOOL := $(CORE_PATH)/tools/bossac/1.7.0-arduino3/bossac.exe

# --- Derived Library/Core Paths (Based on CORE_PATH) ---
VARIANT_PATH := $(CORE_PATH)/ArduinoCore-samd-master/variants/XIAO_m0
ARDUINO_CORE_PATH := $(CORE_PATH)/ArduinoCore-samd-master/cores/arduino
TIMERTC3_PATH := $(CORE_PATH)/ArduinoCore-samd-master/libraries/TimerTC3
TINYUSB_PATH := $(CORE_PATH)/ArduinoCore-samd-master/libraries/Adafruit_TinyUSB_Arduino/src
CMSIS_PATH := $(CORE_PATH)/tools/CMSIS/5.7.0/CMSIS
CMSIS_ATMEL_PATH := $(CORE_PATH)/tools/CMSIS-Atmel/1.2.1/CMSIS-Atmel/CMSIS/Device/ATMEL

# -------------------------------------------------------------------------------
# 2. PROJECT AND BOARD DEFINITIONS
# -------------------------------------------------------------------------------

# Application name and Directories
TARGET := main
SRC_PATH := src
BUILD_PATH := build
LDSCRIPT := flash_with_bootloader.ld # Linker script name in variant folder

# Board-specific settings (Seeed XIAO M0)
MCU := cortex-m0plus
F_CPU := 48000000L
IDE_VERSION := 10607
BOARD := SEEED_XIAO_M0
BUILD_VARIANT := XIAO_m0

# Source files (User Sketch)
SRC_FILE := $(SRC_PATH)/$(TARGET).cpp
MAIN_OBJ := $(BUILD_PATH)/$(TARGET).o

# Core and Library Sources (Using your original logic)
VARIANT_C_SRCS := $(wildcard $(VARIANT_PATH)/*.c)
VARIANT_CPP_SRCS := $(wildcard $(VARIANT_PATH)/*.cpp)
ARDUINO_CORE_C_SRCS := $(wildcard $(ARDUINO_CORE_PATH)/*.c)
ARDUINO_CORE_CPP_SRCS := $(wildcard $(ARDUINO_CORE_PATH)/c/*.cpp)
TIMERTC3_SRCS := $(wildcard $(TIMERTC3_PATH)/*.cpp)
TINYUSB_SRCS := $(wildcard $(TINYUSB_PATH)/*.cpp)

# Object files derivation (Using your original logic)
VARIANT_C_OBJS := $(patsubst $(VARIANT_PATH)/%.c,$(BUILD_PATH)/variant/%.o,$(VARIANT_C_SRCS))
VARIANT_CPP_OBJS := $(patsubst $(VARIANT_PATH)/%.cpp,$(BUILD_PATH)/variant/%.o,$(VARIANT_CPP_SRCS))
ARDUINO_CORE_C_OBJS := $(patsubst $(ARDUINO_CORE_PATH)/%.c,$(BUILD_PATH)/core/%.o,$(ARDUINO_CORE_C_SRCS))
ARDUINO_CORE_CPP_OBJS := $(patsubst $(ARDUINO_CORE_PATH)/%.cpp,$(BUILD_PATH)/core/%.o,$(ARDUINO_CORE_CPP_SRCS))
TIMERTC3_OBJS := $(patsubst $(TIMERTC3_PATH)/%.cpp,$(BUILD_PATH)/timertc3/%.o,$(TIMERTC3_SRCS))
TINYUSB_OBJS := $(patsubst $(TINYUSB_PATH)/%.cpp,$(BUILD_PATH)/tinyusb/%.o,$(filter %.cpp,$(TINYUSB_SRCS)))
TINYUSB_OBJS += $(patsubst $(TINYUSB_PATH)/%.c,$(BUILD_PATH)/tinyusb/%.o,$(filter %.c,$(TINYUSB_SRCS)))

ALL_OBJS = $(MAIN_OBJ) $(VARIANT_C_OBJS) $(VARIANT_CPP_OBJS) $(ARDUINO_CORE_C_OBJS) $(ARDUINO_CORE_CPP_OBJS) $(TIMERTC3_OBJS) $(TINYUSB_OBJS)

# Output files
ELF := $(BUILD_PATH)/$(TARGET).elf
BIN := $(BUILD_PATH)/$(TARGET).bin
MAP := $(BUILD_PATH)/$(TARGET).map

# -------------------------------------------------------------------------------
# 3. COMPILER AND LINKER FLAGS (Extracted directly from your original Makefile)
# -------------------------------------------------------------------------------

BUILD_USB_FLAGS := -DUSB_VID=0x2886 -DUSB_PID=0x802F -DUSBCON -DUSB_CONFIG_POWER=100 -DUSB_MANUFACTURER="\"Seeed\"" -DUSB_PRODUCT="\"Seeed XIAO M0\"" -DUSE_TINYUSB "-I$(TINYUSB_PATH)/arduino"
BUILD_EXTRA_FLAGS := -DARDUINO_SAMD_ZERO -D__SAMD21__ -D__SAMD21G18A__ -DARM_MATH_CM0PLUS -DSEEED_XIAO_M0 $(BUILD_USB_FLAGS)
ARM_CMCIS_C_FLAGS := "-I$(CMSIS_PATH)/Core/Include" "-I$(CMSIS_PATH)/DSP/Include" "-I$(CMSIS_ATMEL_PATH)"

# --- Includes ---
INCLUDES := \
	-I$(ARDUINO_CORE_PATH) \
	-I$(VARIANT_PATH) \
	-I$(TIMERTC3_PATH) \
	-I$(TINYUSB_PATH) \
	-I$(CMSIS_PATH)/Core/Include \
	-I$(CMSIS_PATH)/DSP/Include \
	-I$(CMSIS_ATMEL_PATH)/samd21/include \
	-I$(CMSIS_ATMEL_PATH)/samd21/source \
	-I$(CMSIS_ATMEL_PATH)

# --- C & C++ Flags ---
COMMON_COMP_FLAGS := -mcpu=$(MCU) -mthumb -c -g -Os -w -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD -D__SKETCH_NAME__=\"$(TARGET)\"
CORE_DEFINES := -DF_CPU=$(F_CPU) -DARDUINO=$(IDE_VERSION) -DARDUINO_$(BOARD) $(BUILD_EXTRA_FLAGS) $(ARM_CMCIS_C_FLAGS)

CFLAGS := $(COMMON_COMP_FLAGS) -std=gnu11 $(CORE_DEFINES)
CXXFLAGS := $(COMMON_COMP_FLAGS) -std=gnu++14 -fno-threadsafe-statics -fno-rtti -fno-exceptions $(CORE_DEFINES)

# --- Linker Flags ---
LDF := $(PREFIX)g++
CMSIS_LDFLAGS := -L$(CMSIS_PATH)/DSP/Lib/GCC -larm_cortexM0l_math -lm
LDFLAGS := -mcpu=$(MCU) -mthumb -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align -u _printf_float -u _scanf_float -Wl,--wrap,_write -u __wrap__write
LINK_LIBS := -Wl,--start-group $(CMSIS_LDFLAGS) -L$(VARIANT_PATH) -lm -Wl,--end-group
LINK_SPEC := --specs=nano.specs --specs=nosys.specs

# --- Binary Copy Flags ---
OBJCOPYFLAGS := -O binary

# -------------------------------------------------------------------------------
# 4. BUILD MACROS AND RULES (Cross-Platform)
# -------------------------------------------------------------------------------

# Cross-Platform File Management Macros
# Windows uses 'if not exist' and 'rmdir /S /Q'
ifeq ($(OS),Windows_NT)
MKDIR_P = if not exist "$1" mkdir "$1"
RM_RF = if exist "$1" rmdir /S /Q "$1"
else
# Linux/macOS uses 'mkdir -p' and 'rm -rf'
MKDIR_P = mkdir -p "$1"
RM_RF = rm -rf "$1"
endif

# Define compilation macros
define COMPILE_C
	@echo "  CC $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -o "$2" "$1"
endef

define COMPILE_CXX
	@echo " CXX $<"
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -o "$2" "$1"
endef

.PHONY: all build clean upload size detect-bootloader flash-to-bootloader upload-reset flash-reset dirs

all: clean build detect-bootloader flash-to-bootloader

# --- Directory Setup (Cross-Platform) ---
dirs:
	@$(call MKDIR_P, $(BUILD_PATH))
	@$(call MKDIR_P, $(BUILD_PATH)/core)
	@$(call MKDIR_P, $(BUILD_PATH)/variant)
	@$(call MKDIR_P, $(BUILD_PATH)/timertc3)
	@$(call MKDIR_P, $(BUILD_PATH)/tinyusb)

build: dirs $(BIN)

clean:
	@echo "Cleaning build directory: $(BUILD_PATH)"
	@$(call RM_RF, $(BUILD_PATH))

# --- Compilation Rules (Using your original logic) ---

$(MAIN_OBJ): $(SRC_FILE)
	@echo "Compiling sketch: $<"
	@$(call COMPILE_CXX,$<,$@)

$(VARIANT_C_OBJS): $(BUILD_PATH)/variant/%.o: $(VARIANT_PATH)/%.c
	@$(call COMPILE_C,$<,$@)

$(VARIANT_CPP_OBJS): $(BUILD_PATH)/variant/%.o: $(VARIANT_PATH)/%.cpp
	@$(call COMPILE_CXX,$<,$@)

$(ARDUINO_CORE_C_OBJS): $(BUILD_PATH)/core/%.o: $(ARDUINO_CORE_PATH)/%.c
	@$(call COMPILE_C,$<,$@)

$(ARDUINO_CORE_CPP_OBJS): $(BUILD_PATH)/core/%.o: $(ARDUINO_CORE_PATH)/%.cpp
	@$(call COMPILE_CXX,$<,$@)

$(TIMERTC3_OBJS): $(BUILD_PATH)/timertc3/%.o: $(TIMERTC3_PATH)/%.cpp
	@$(call COMPILE_CXX,$<,$@)

$(TINYUSB_OBJS): $(BUILD_PATH)/tinyusb/%.o: $(TINYUSB_PATH)/%.c
	@$(call COMPILE_C,$<,$@)

$(TINYUSB_OBJS): $(BUILD_PATH)/tinyusb/%.o: $(TINYUSB_PATH)/%.cpp
	@$(call COMPILE_CXX,$<,$@)

# --- Linking, Binary, and Size ---

$(ELF): $(ALL_OBJS)
	@echo "Linking: $@"
	@$(LDF) -T"$(VARIANT_PATH)/$(LDSCRIPT)" "-Wl,-Map,$(MAP)" $(LINK_SPEC) $(LDFLAGS) -o "$@" $(ALL_OBJS) $(LINK_LIBS)
	@echo "Size report:"
	@$(SIZE) -A "$@"

$(BIN): $(ELF)
	@echo "Creating binary: $@"
	@$(OBJCOPY) $(OBJCOPYFLAGS) "$<" "$@"

# --- Upload Targets (NOTE: These remain Windows-specific for functionality) ---
detect-bootloader:
	@echo "--- Resetting device on $(SERIAL_PORT) with 1200bps touch... ---"
	@mode $(SERIAL_PORT): baud=1200 >nul
	@echo "Waiting for bootloader..."
	@powershell -NoProfile -Command " \
		$$before = @(Get-WmiObject Win32_SerialPort | Select-Object -ExpandProperty DeviceID); \
		Start-Sleep -Seconds 2; \
		$$after = Get-WmiObject Win32_SerialPort | Select-Object -ExpandProperty DeviceID; \
		$$new_port = Compare-Object $$before $$after | Where-Object {$$_.SideIndicator -eq '=>'} | ForEach-Object {$$_.InputObject}; \
		if ($$new_port) { \
			Write-Host ('New bootloader COM port found: ' + $$new_port) -ForegroundColor Green; \
		} else { \
			Write-Host 'No new COM port detected. The board may have reused the same port.' -ForegroundColor Yellow; \
		} \
	"

flash-to-bootloader:
	@echo "Flashing to bootloader on $(BOOTLOADER_PORT)..."
	@$(BOSSAC_TOOL) -i -d --port=$(BOOTLOADER_PORT) -U true -i -e -w -v $(BIN) -R

upload: detect-bootloader flash-to-bootloader