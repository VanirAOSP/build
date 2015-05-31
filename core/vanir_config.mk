#
# Copyright (C) 2014 VanirAOSP && The Android Open Source Project
# Copyright (C) 2015 Exodus/Vanir
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#  This config sets up an interface for toggling various build configurations
#  that can be set and respected in device tree overlays.  All options should
#  default off if unset.  The vanir_config.mk is included in:
#    $(BUILD_SYSTEM)/config.mk

# current build configurations:
# BONE_STOCK := set true to override all vanir_config variables
# NO_DEBUG_FRAME_POINTERS := set true to add frame pointers
# NO_DEBUG_SYMBOL_FLAGS := true removes debugging code insertions from assert.h macros and GDB
# MAXIMUM_OVERDRIVE := true disables address sanitizer, in core/clang/config.mk
# USE_GRAPHITE := true adds graphite cflags to turn on graphite
# USE_FSTRICT_FLAGS := true builds with fstrict-aliasing (thumb and arm)
# USE_BINARY_FLAGS := true adds experimental binary flags that can be set here or in device trees
# USE_EXTRA_CLANG_FLAGS := true allows additional flags to be passed to the Clang compiler
# ADDITIONAL_TARGET_ARM_OPT := Additional flags may be appended here for GCC-specific modules, -O3 etc
# ADDITIONAL_TARGET_THUMB_OPT := Additional flags may be appended here for GCC-specific modules, -O3 etc
# VANIR_ARM_OPT_LEVEL := -Ox for TARGET_arm_CFLAGS, preserved in binary.mk
# VANIR_THUMB_OPT_LEVEL := -Ox for TARGET_thumb_CFLAGS, preserved in binary.mk
# FSTRICT_ALIASING_WARNING_LEVEL := 0-3 for the level of intensity the compiler checks for violations.
# USE_LTO := true builds locally in modules with the -flto flags set in this config file
# LTO_COMPRESSION_LEVEL := 0-9 0 being none 9 being the most available

# SET GLOBAL CONFIGURATION HERE:
MAXIMUM_OVERDRIVE           ?= true
NO_DEBUG_SYMBOL_FLAGS       ?= true
NO_DEBUG_FRAME_POINTERS     ?= true
USE_GRAPHITE                ?=
USE_LTO                     ?= true
USE_FSTRICT_FLAGS           ?= true
USE_BINARY_FLAGS            ?=
USE_EXTRA_CLANG_FLAGS       ?=
ADDITIONAL_TARGET_ARM_OPT   ?=
ADDITIONAL_TARGET_THUMB_OPT ?=
VANIR_ARM_OPT_LEVEL         ?= -O2
VANIR_THUMB_OPT_LEVEL       ?= -O2
FSTRICT_ALIASING_WARNING_LEVEL ?= 2
LTO_COMPRESSION_LEVEL ?= 3

# Respect BONE_STOCK: strictly enforce AOSP defaults.
ifeq ($(BONE_STOCK),true)
  MAXIUMUM_OVERDRIVE      :=
  NO_DEBUG_SYMBOL_FLAGS   :=
  USE_GRAPHITE            :=
  USE_FSTRICT_FLAGS       :=
  USE_BINARY_FLAGS        :=
  USE_EXTRA_CLANG_FLAGS   :=
  VANIR_ARM_OPT_LEVEL     := -O2
  VANIR_THUMB_OPT_LEVEL   := -Os
  ADDITIONAL_TARGET_ARM_OPT   :=
  ADDITIONAL_TARGET_THUMB_OPT :=
endif

# DEBUGGING OPTIONS
ifeq ($(NO_DEBUG_SYMBOL_FLAGS),true)
  DEBUG_SYMBOL_FLAGS := -DNDEBUG
endif
ifeq ($(NO_DEBUG_FRAME_POINTERS),true)
  DEBUG_FRAME_POINTER_FLAGS := -fomit-frame-pointer
endif

# GRAPHITE
ifeq ($(USE_GRAPHITE),true)
  GRAPHITE_FLAGS := \
          -fgraphite             \
          -floop-flatten         \
          -floop-parallelize-all \
          -ftree-loop-linear     \
          -floop-interchange     \
          -floop-strip-mine      \
          -floop-block
endif

# Assign modules to build with link time optimizations using VANIR_LTO_MODULES.
ifeq ($(USE_LTO),true)
  VANIR_LTO_FLAGS := \
    -flto \
    -fwhopr \
    -flto-compression-level=$(LTO_COMPRESSION_LEVEL) \
    -fuse-ld=gold \
    -flto-report
endif

# the modules on this list will be compile with link time optimizations. 
# anything not on the list will not be compiled with link time optimizations
# feel free to add or remove things from this list as seen fit.
ifeq ($(USE_LTO),true)
  VANIR_LTO_MODULES := \
    bluetooth.default \
    busybox \
    content_content_renderer_gyp \
    dnsmasq \
    gatt_testtool \
    libandroidfw \
    libandroid_runtime \
    libaudioflinger \
    libc \
    libc_dns \
    libc_gdtoa \
    libc_nomalloc \
    libc_openbsd \
    libc_tzcode \
    libdiskconfig \
    libdownmix \
    libft2 \
    libfusetwrp \
    libguitwrp \
    libjni_filtershow_filters \
    libjni_jpegstream \
    libjni_jpegutil \
    libldnhncr \
    libmedia \
    libmediaplayerservice \
    libmusicbundle \
    libnfc-nci \
    libnvvisualizer \
    libOmxVdec \
    libOmxVenc \
    libpdfium \
    libpdfiumcore \
    libqcomvisualizer \
    libreverb \
    librtp_jni \
    libssh \
    libstagefright \
    libstagefright_soft_h264dec \
    libstagefright_webm \
    libstlport \
    libstlport_static \
    libtwrpmtp \
    libuclibcrpc \
    libvariablespeed \
    libvisualizer \
    libwebviewchromium \
    libwebviewchromium_loader \
    libwebviewchromium_plat_support \
    libwilhelm \
    libziparchive-host \
    libziparchive \
    logd \
    mdnsd \
    mm-vdec-omx-test \
    net_net_gyp \
    ping6 \
    ping \
    ssh \
    static_busybox \
    third_party_angle_src_translator_lib_gyp \
    third_party_WebKit_Source_core_webcore_generated_gyp \
    third_party_WebKit_Source_core_webcore_remaining_gyp \
    third_party_WebKit_Source_modules_modules_gyp \
    third_party_WebKit_Source_platform_blink_platform_gyp
endif

# fstrict-aliasing. Thumb is defaulted off for AOSP. Use VANIR_SPECIAL_CASE_MODULES to
# temporarily disable fstrict-aliasing locally in modules we dont care about or until the
# error it contains is properly fixed.
#
# Style points will be assessed for tagging modules with their path for future fixing
ifeq ($(USE_FSTRICT_FLAGS),true)
  VANIR_FNO_STRICT_ALIASING_MODULES := \
    audio.primary.msm8960 \
    audio.primary.msm8974 \
    audio_policy.msm8610 \
    bluetooth.default \
    busybox \
    content_content_renderer_gyp \
    dnsmasq \
    gatt_testtool \
    libandroidfw \
    libandroid_runtime \
    libaudioflinger \
    libc \
    libc_dns \
    libc_gdtoa \
    libc_nomalloc \
    libc_openbsd \
    libc_tzcode \
    libdiskconfig \
    libdownmix \
    libft2 \
    libfusetwrp \
    libguitwrp \
    libjni_filtershow_filters \
    libjni_jpegstream \
    libjni_jpegutil \
    libldnhncr \
    libmedia \
    libmediaplayerservice \
    libmusicbundle \
    libnfc-nci \
    libnvvisualizer \
    libOmxVdec \
    libOmxVenc \
    libpdfium \
    libpdfiumcore \
    libqcomvisualizer \
    libreverb \
    librtp_jni \
    libssh \
    libstagefright \
    libstagefright_soft_h264dec \
    libstagefright_webm \
    libstlport \
    libstlport_static \
    libtwrpmtp \
    libuclibcrpc \
    libvariablespeed \
    libvisualizer \
    libwebviewchromium \
    libwebviewchromium_loader \
    libwebviewchromium_plat_support \
    libwilhelm \
    libziparchive-host \
    libziparchive \
    logd \
    mdnsd \
    mm-vdec-omx-test \
    net_net_gyp \
    ping6 \
    ping \
    sensors.$(TARGET_BOOTLOADER_BOARD_NAME) \
    ssh \
    static_busybox \
    third_party_angle_src_translator_lib_gyp \
    third_party_WebKit_Source_core_webcore_generated_gyp \
    third_party_WebKit_Source_core_webcore_remaining_gyp \
    third_party_WebKit_Source_modules_modules_gyp \
    third_party_WebKit_Source_platform_blink_platform_gyp

# external/ffmpeg
  VANIR_FNO_STRICT_ALIASING_MODULES += \
    libavcodec \
    libavformat \
    libavutil \
    libswscale

# this shit is deplorable. die in a fire.
  VANIR_FNO_STRICT_ALIASING_MODULES += \
    libtee_client_api_driver

FSTRICT_FLAGS := \
        -Wstrict-aliasing=$(FSTRICT_ALIASING_WARNING_LEVEL) \
        -Werror=strict-aliasing
endif

# Additional GCC-specific arm cflags
ifeq ($(ADDITIONAL_TARGET_ARM_OPT),true)
    VANIR_TARGET_ARM_FLAGS := \
        -ftree-vectorize \
        -funsafe-loop-optimizations
endif

# Additional GCC-specific thumb cflags
ifeq ($(ADDITIONAL_TARGET_THUMB_OPT),true)
    VANIR_TARGET_THUMB_FLAGS := \
        -funsafe-math-optimizations
endif

# Additional clang-specific cflags
ifeq ($(USE_EXTRA_CLANG_FLAGS),true)
    VANIR_CLANG_CONFIG_EXTRA_ASFLAGS :=
    VANIR_CLANG_CONFIG_EXTRA_CFLAGS := -O2 -Qunused-arguments -Wno-unknown-warning-option
    VANIR_CLANG_CONFIG_EXTRA_CPPFLAGS := -O2 -Qunused-arguments -Wno-unknown-warning-option
    VANIR_CLANG_CONFIG_EXTRA_LDFLAGS := -Wl,--sort-common
endif

#======================================================================================================
# variables as exported to other makefiles ============================================================
VANIR_FSTRICT_OPTIONS := $(FSTRICT_FLAGS)

VANIR_GLOBAL_CFLAGS += $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)
VANIR_RELEASE_CFLAGS += $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)
VANIR_CLANG_TARGET_GLOBAL_CFLAGS += $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)
VANIR_GLOBAL_CPPFLAGS += $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)

# set experimental/unsupported flags here for persistance and try to override local options that
# may be set after release flags.  This option should not be used to set flags globally that are
# intended for release but to test outcomes.  For example: setting -O3 here will have a higher
# likelyhood of overriding the stock and local flags.
ifdef ($(USE_BINARY_FLAGS),true)
VANIR_BINARY_CFLAG_OPTIONS := $(GRAPHITE_FLAGS)
VANIR_BINARY_CPP_OPTIONS := $(GRAPHITE_FLAGS)
VANIR_LINKER_OPTIONS :=
VANIR_ASSEMBLER_OPTIONS :=
endif
