# -------------------------------------------------------------------------------
# config.mk - Local/Machine-Specific Configuration for Embedded Build
# -------------------------------------------------------------------------------
#
# This file MUST be created by the user and should NOT be committed to the public
# GitHub repository, as it contains local machine paths.
#
# IMPORTANT: Define the paths based on your local machine setup.

# 1. Path to the 'bin' directory of the Arm GNU Toolchain.
# Example: C:/Users/soham/tools/arm-none-eabi-gcc/7-2017q4/bin/
TOOLCHAIN_PATH = 

# 2. Base path to the extracted ArduinoCore-samd-master folder.
# Example: C:/Users/soham/Documents/ArduinoCore-samd-master
CORE_PATH = 

# 3. Serial Port settings for the Windows 'upload' target
SERIAL_PORT = COM4
BOOTLOADER_PORT = COM5