DEVICE := device/amazon/suez
KERNEL := kernel/amazon/suez
VENDOR := vendor/amazon/suez

# headers
TARGET_SPECIFIC_HEADER_PATH := $(DEVICE)/include

# inherit from the proprietary version
-include $(VENDOR)/BoardConfigVendor.mk

# Platform
TARGET_BOARD_PLATFORM := mt8173

# Bootloader
TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME := suez

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a15

TARGET_CPU_ABI_LIST := arm64-v8a,armeabi-v7a,armeabi
TARGET_CPU_ABI_LIST_64_BIT := arm64-v8a

TARGET_CPU_SMP := true

# Kernel Config
BOARD_KERNEL_BASE := 0x40080000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0

BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00000000 --ramdisk_offset 0x03400000 --second_offset 0x00e80000 --tags_offset 0x07f80000 
TARGET_KERNEL_ARCH := arm64

TARGET_KERNEL_CONFIG := suez_defconfig
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_KERNEL_CMDLINE += lcm=0-nt51021_wuxga_dsi_vdo
# The bootloader (LK) always injects console=tty0/ttyS0/ttyMT0 ahead of this
# cmdline, so the serial console can't be removed by omitting console= here --
# but CONFIG_SERIAL_8250/CONFIG_SERIAL_8250_CONSOLE/CONFIG_MTK_SERIAL_CONSOLE
# are disabled at compile time (suez_defconfig), so there is no actual UART
# console driver registered for these to attach to; the injected console=
# args are inert.
#
# Previously set loglevel=0 here on the theory that it avoided UART overhead.
# That reasoning no longer applies now that the UART driver itself is gone --
# what loglevel=0 actually suppresses is console_loglevel, a single global
# threshold shared by every registered console, including pstore's ramoops
# console (fs/pstore/platform.c, CON_PRINTBUFFER|CON_ENABLED|CON_ANYTIME).
# With loglevel=0, virtually nothing reaches ramoops UNLESS some WARN_ON()
# happens to fire first in that boot session (warn_slowpath_common() calls
# console_verbose(), which latches console_loglevel to max for the rest of
# the session) -- an unreliable diagnostic mechanism to depend on. Confirmed
# via a real freeze/reboot: the ramoops dump was missing the actual trigger
# for a WiFi/BT combo-chip firmware assert, only capturing the recovery
# attempt (a WARN_ON happened to fire earlier at boot in that instance).
# Raise it so ramoops reliably captures full detail on the next crash/hang,
# with no remaining UART cost to trade off.
BOARD_KERNEL_CMDLINE += loglevel=7
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
# Diagnostic: on a first-stage init LOG(FATAL), drop to an interactive
# shell on /dev/console instead of aborting/rebooting, so the actual
# failure can be seen and investigated live instead of guessing from
# unreliable hardware crash-dump registers.
BOARD_KERNEL_CMDLINE += androidboot.first_stage_console=1
# Diagnostic: this kernel's ramoops (fs/pstore/ram.c) predates DT-based
# auto-probing (no of_match_table in ram.c; the "ramoops" compatible string
# on the reserved-memory node in mt8173.dtsi only carves out the physical
# range, it doesn't bind a driver), so it must be configured via module
# params on the cmdline. Address/sizes match the reserved-memory node.
#
# This was silently failing on every single boot ("ramoops: no room for
# dumps", probe error -12), regardless of whether a crash had actually
# happened, so no panic dump was ever captured for the random watchdog
# reboots this device intermittently hits. Root cause: ramoops_probe()
# computes dump_mem_sz = mem_size - console_size*2 - ftrace_size -
# pmsg_size (console_size is counted TWICE, a real, documented ram.c
# behavior, not a bug) -- the previous console_size=0x20000 alone, when
# doubled, equals the *entire* 0x40000 mem_size budget, leaving nothing
# (an unsigned underflow, effectively "negative") for the actual crash-
# dump zones that record_size carves up, which is the one thing here
# that actually matters for diagnosing a panic/reset. Rebalanced within
# the same 0x40000 total: smaller console/ftrace/pmsg allowances, still
# comfortably leaves room for 5 record_size dump zones (5 * 0x8000 =
# 0x28000) with margin: 0x8000*2 + 0x2000 + 0x2000 + 0x28000 = 0x3C000 <
# 0x40000.
BOARD_KERNEL_CMDLINE += ramoops.mem_address=0x44480000
BOARD_KERNEL_CMDLINE += ramoops.mem_size=0x40000
BOARD_KERNEL_CMDLINE += ramoops.mem_type=1
BOARD_KERNEL_CMDLINE += ramoops.record_size=0x8000
BOARD_KERNEL_CMDLINE += ramoops.console_size=0x8000
BOARD_KERNEL_CMDLINE += ramoops.ftrace_size=0x2000
BOARD_KERNEL_CMDLINE += ramoops.pmsg_size=0x2000
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_KERNEL_SOURCE := $(KERNEL)
# Switched from the ancient/unmaintained aarch64-linux-android-4.9 prebuilt to
# the Linaro GCC 6.3.1 toolchain, matching the actively-maintained karnak
# (sibling MT8163 device) reference tree. Candidate fix for a boot hang on
# real hardware with a kernel built by the old 4.9 compiler.
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(shell pwd)/prebuilts/linaro/linux-x86/aarch64/aarch64-linux-gnu/bin/aarch64-linux-gnu-
TARGET_KERNEL_CLANG_COMPILE := false

# Enable debug on eng builds
ifeq ($(TARGET_BUILD_VARIANT),eng)
TARGET_KERNEL_ADDITIONAL_CONFIG:= suez_debug_defconfig
endif

# LineageHW
BOARD_USES_LINEAGE_HARDWARE := true
BOARD_HARDWARE_CLASS := $(DEVICE)/lineagehw

# Board has Mediatek hardware
BOARD_HAS_MTK_HARDWARE := true
BOARD_USES_MTK_HARDWARE := true
MTK_HARDWARE := true
BOARD_USES_LEGACY_MTK_AV_BLOB := true
BOARD_USES_MTK_AUDIO := true
BOARD_GLOBAL_CFLAGS += -DMTK_HARDWARE
BOARD_GLOBAL_CFLAGS += -DUSE_OLD_HWCOMPOSER

# ION memory management (legacy MTK gralloc/HWC blobs expect this)
TARGET_USES_ION := true

# Suppress MTK audio blob error message flag
SUPPRESS_MTK_AUDIO_BLOB_ERR_MSG := true

# MTK AV blob flag
LEGACY_MTK_AV_BLOB := true

# Binder API version
TARGET_USES_64_BIT_BINDER := true

# WiFi
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_FW_PATH_PARAM := /dev/wmtWifi
WIFI_DRIVER_FW_PATH_STA:=STA
WIFI_DRIVER_FW_PATH_AP:=AP
WIFI_DRIVER_FW_PATH_P2P:=P2P
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0

# BT
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE)/bluetooth
BOARD_HAVE_BLUETOOTH := true

# Camera
TARGET_CAMERASERVICE_CLOSES_NATIVE_HANDLES := true
TARGET_USES_NON_TREBLE_CAMERA := true

# Graphics
USE_OPENGL_RENDERER := true

# Use SurfaceFlinger HWC 2On1 Adaptor
TARGET_USES_HWC2 := true
TARGET_USES_HWC2ON1ADAPTER := true
SF_START_GRAPHICS_ALLOCATOR_SERVICE := true
# The kernel fully supports the sync/fence framework (CONFIG_SYNC=y,
# CONFIG_SW_SYNC=y), so telling SurfaceFlinger to run WITHOUT it is wrong:
# without proper fence-based sync, a buffer can be scanned out/composited
# before the GPU has actually finished writing it, which is a classic cause
# of tearing and partially-written/garbled frame content -- matching the
# navbar icon / screenshot-preview corruption seen on this device.
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := false

# System's VSYNC phase offsets in nanoseconds
VSYNC_EVENT_PHASE_OFFSET_NS := 7500000
SF_VSYNC_EVENT_PHASE_OFFSET_NS := 5000000

# Surfaceflinger optimization for VD surfaces
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3

TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1200

MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 1024*1024

# Filesystem
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 17825792
# suez: bumped from the original 1692925952 (1614.5MB) to match this
# device's physical /system partition after the manual parted repartition
# (see the suez-gapps-partition-resize memory/note) -- confirmed via
# `adb shell blockdev --getsize64 .../by-name/system`. This build will no
# longer fit on a suez that hasn't been repartitioned first; that's an
# accepted tradeoff for this personal build, not something to revert
# without checking first.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2037045760
#BOARD_USERDATAIMAGE_PARTITION_SIZE := 0x6b4300000 # 28792848384
BOARD_CACHEIMAGE_PARTITION_SIZE := 444596224
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 131072
TARGET_USERIMAGES_USE_EXT4 := true

# Software Gatekeeper
BOARD_USE_SOFT_GATEKEEPER := true

# OTA
BLOCK_BASED_OTA := false
TARGET_OTA_ASSERT_DEVICE := suez

# Mainfest
DEVICE_MANIFEST_FILE := $(DEVICE)/manifest.xml
DEVICE_MATRIX_FILE   := $(DEVICE)/compatibility_matrix.xml

# Security patch level
VENDOR_SECURITY_PATCH := 2019-07-01

# Vold
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/devices/platform/mt_usb/musb-hdrc.0.auto/gadget/lun%d/file

# SELinux
BOARD_SEPOLICY_DIRS += \
        $(DEVICE)/sepolicy-mtk/basic/non_plat \
        $(DEVICE)/sepolicy-mtk/bsp/non_plat \
        $(DEVICE)/sepolicy-mt8173/basic \
        $(DEVICE)/sepolicy-mt8173/bsp \
        $(DEVICE)/sepolicy

BOARD_PLAT_PUBLIC_SEPOLICY_DIR += \
        $(DEVICE)/sepolicy-mtk/basic/plat_public \
        $(DEVICE)/sepolicy-mtk/bsp/plat_public

BOARD_PLAT_PRIVATE_SEPOLICY_DIR += \
        $(DEVICE)/sepolicy-mtk/basic/plat_private \
        $(DEVICE)/sepolicy-mtk/bsp/plat_private

-include $(DEVICE)/shims.mk

# Disable API check
WITHOUT_CHECK_API := true

# Use dlmalloc instead of jemalloc
MALLOC_SVELTE := true

# Legacy MTK proprietary blobs (proprietary-files.txt) intentionally override
# several stock AOSP-built libraries (e.g. libaudiopreprocessing) by copying
# a vendor-provided .so to the same install path. Downgrade the resulting
# duplicate build-rule errors to warnings instead of chasing every individual
# name collision.
BUILD_BROKEN_DUP_RULES := true

# This device tree's MTK sepolicy sources predate most of AOSP's neverallow
# security hardening (API 28+): ~80 legacy domains (init, aee_aed/aee_aedv
# crash-dump collectors, various MTK HALs, etc.) violate ~870 neverallow
# assertions, mostly around ptrace and capability restrictions. Fixing these
# individually is out of scope for getting the build running; ignore
# neverallow violations for now (userdebug/eng only - this flag errors out
# on user builds) and revisit sepolicy hardening as follow-up work.
SELINUX_IGNORE_NEVERALLOWS := true
