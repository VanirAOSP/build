#
# Copyright (C) 2006 The Android Open Source Project
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
#

# Configuration for Linux on ARM.
# Included by combo/select.mk

# You can set TARGET_ARCH_VARIANT to use an arch version other
# than ARMv5TE. Each value should correspond to a file named
# $(BUILD_COMBOS)/arch/<name>.mk which must contain
# makefile variable definitions similar to the preprocessor
# defines in build/core/combo/include/arch/<combo>/AndroidConfig.h. Their
# purpose is to allow module Android.mk files to selectively compile
# different versions of code based upon the funtionality and
# instructions available in a given architecture version.
#
# The blocks also define specific arch_variant_cflags, which
# include defines, and compiler settings for the given architecture
# version.
#
ifeq ($(strip $(TARGET_$(combo_2nd_arch_prefix)ARCH_VARIANT)),)
TARGET_$(combo_2nd_arch_prefix)ARCH_VARIANT := armv5te
endif

<<<<<<< HEAD
# default target GCC version
ifneq ($(strip $(BONE_STOCK)),)
TARGET_GCC_VERSION := 4.7
else
ifeq ($(strip $(TARGET_GCC_VERSION)),)
TARGET_GCC_VERSION := 4.8-linaro
endif
=======
# Decouple NDK library selection with platform compiler version
$(combo_2nd_arch_prefix)TARGET_NDK_GCC_VERSION := 4.8

ifeq ($(strip $(TARGET_GCC_VERSION_EXP)),)
$(combo_2nd_arch_prefix)TARGET_GCC_VERSION := 4.8
else
$(combo_2nd_arch_prefix)TARGET_GCC_VERSION := $(TARGET_GCC_VERSION_EXP)
>>>>>>> android-5.0.0_r2
endif

TARGET_ARCH_SPECIFIC_MAKEFILE := $(BUILD_COMBOS)/arch/$(TARGET_$(combo_2nd_arch_prefix)ARCH)/$(TARGET_$(combo_2nd_arch_prefix)ARCH_VARIANT).mk
ifeq ($(strip $(wildcard $(TARGET_ARCH_SPECIFIC_MAKEFILE))),)
$(error Unknown ARM architecture version: $(TARGET_$(combo_2nd_arch_prefix)ARCH_VARIANT))
endif

ifeq ($(strip $(DONT_WARN_STRICT_ALIASING)),)
STRICT_ALIASING_WARNINGS := \
                        -Wstrict-aliasing=2 \
                        -Werror=strict-aliasing
else
STRICT_ALIASING_WARNINGS := \
                        -Wno-strict-aliasing
endif

ifeq ($(strip $(BONE_STOCK)),)
TARGET_ARM_O := 3
TARGET_THUMB_O := s
TARGET_THUMB_STRICT := \
    -fstrict-aliasing
# aosp gcc 4.7 barfs with ftree-vectorize
ifneq ($(filter 4.7 4.7.%, $(shell $(TARGET_CC) --version)),)
TARGET_EXTRA_BULLSHIT_1 += \
                       -ftree-vectorize
endif
TARGET_EXTRA_BULLSHIT_2 += \
                       -funsafe-loop-optimizations
TARGET_THUMB_BULLSHIT += \
                       -funsafe-math-optimizations
else
TARGET_ARM_O := 2
TARGET_THUMB_O := s
TARGET_THUMB_STRICT := \
    -fno-strict-aliasing
endif

include $(TARGET_ARCH_SPECIFIC_MAKEFILE)
include $(BUILD_SYSTEM)/combo/fdo.mk

# You can set TARGET_TOOLS_PREFIX to get gcc from somewhere else
ifeq ($(strip $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)),)
$(combo_2nd_arch_prefix)TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/$(HOST_PREBUILT_TAG)/arm/arm-linux-androideabi-$($(combo_2nd_arch_prefix)TARGET_GCC_VERSION)
$(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX := $($(combo_2nd_arch_prefix)TARGET_TOOLCHAIN_ROOT)/bin/arm-linux-androideabi-
endif

$(combo_2nd_arch_prefix)TARGET_CC := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)gcc$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_CXX := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)g++$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_AR := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)ar$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_OBJCOPY := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)objcopy$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_LD := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)ld$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_READELF := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)readelf$(HOST_EXECUTABLE_SUFFIX)
$(combo_2nd_arch_prefix)TARGET_STRIP := $($(combo_2nd_arch_prefix)TARGET_TOOLS_PREFIX)strip$(HOST_EXECUTABLE_SUFFIX)

$(combo_2nd_arch_prefix)TARGET_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined

<<<<<<< HEAD
# ARM specific
TARGET_arm_CFLAGS :=    -O$(TARGET_ARM_O) \
=======
$(combo_2nd_arch_prefix)TARGET_arm_CFLAGS :=    -O2 \
>>>>>>> android-5.0.0_r2
                        -fomit-frame-pointer \
                        -fstrict-aliasing $(TARGET_EXTRA_BULLSHIT_1) \
                        -funswitch-loops $(TARGET_EXTRA_BULLSHIT_2)

<<<<<<< HEAD
TARGET_arm_CFLAGS += \
                        $(STRICT_ALIASING_WARNINGS) $(DEBUG_SYMBOL_FLAGS)

# THUMB2 specific
TARGET_thumb_CFLAGS :=  -mthumb \
                        -O$(TARGET_THUMB_O) \
                        -fomit-frame-pointer $(TARGET_THUMB_BULLSHIT) \
                        $(TARGET_THUMB_STRICT) $(STRICT_ALIASING_WARNINGS) $(DEBUG_SYMBOL_FLAGS)

#SHUT THE F$#@ UP!
TARGET_arm_CFLAGS +=    -Wno-unused-parameter \
                        -Wno-unused-value \
                        -Wno-unused-function

TARGET_thumb_CFLAGS +=  -Wno-unused-parameter \
                        -Wno-unused-value \
                        -Wno-unused-function

# Global defines for skia neon optimization
ifeq ($(ARCH_ARM_HAVE_NEON),true)
  TARGET_GLOBAL_CFLAGS += -DSKPAINTOPTIONS_OPT
  TARGET_GLOBAL_CPPFLAGS += -DSKPAINTOPTIONS_OPT
endif

# Turn off strict-aliasing if we're building an AOSP variant without the
# patchset...
ifeq ($(strip $(BONE_STOCK)),)
ifeq ($(DEBUG_NO_STRICT_ALIASING),yes)
TARGET_arm_CFLAGS += -fno-strict-aliasing -Wno-error=strict-aliasing
TARGET_thumb_CFLAGS += -fno-strict-aliasing -Wno-error=strict-aliasing
endif   
endif
=======
# Modules can choose to compile some source as thumb.
$(combo_2nd_arch_prefix)TARGET_thumb_CFLAGS :=  -mthumb \
                        -Os \
                        -fomit-frame-pointer \
                        -fno-strict-aliasing
>>>>>>> android-5.0.0_r2

# Set FORCE_ARM_DEBUGGING to "true" in your buildspec.mk
# or in your environment to force a full arm build, even for
# files that are normally built as thumb; this can make
# gdb debugging easier. Don't forget to do a clean build.
#
# NOTE: if you try to build a -O0 build with thumb, several
# of the libraries (libpv, libwebcore, libkjs) need to be built
# with -mlong-calls.  When built at -O0, those libraries are
# too big for a thumb "BL <label>" to go from one end to the other.
ifeq ($(FORCE_ARM_DEBUGGING),true)
  $(combo_2nd_arch_prefix)TARGET_arm_CFLAGS += -fno-omit-frame-pointer -fno-strict-aliasing
  $(combo_2nd_arch_prefix)TARGET_thumb_CFLAGS += -marm -fno-omit-frame-pointer
endif

ifeq ($(TARGET_DISABLE_ARM_PIE),true)
   PIE_GLOBAL_CFLAGS :=
   PIE_EXECUTABLE_TRANSFORM :=
else
   PIE_GLOBAL_CFLAGS := -fPIE
   PIE_EXECUTABLE_TRANSFORM := -fPIE -pie
endif
android_config_h := $(call select-android-config-h,linux-arm)

<<<<<<< HEAD
NO_CANONICAL_SYSTEM_HEADERS :=
ifeq ($(filter 4.6 4.6.% 4.7 4.7.%, $(shell $(TARGET_CC) --version)),)
NO_CANONICAL_SYSTEM_HEADERS := \
			-fno-canonical-system-headers
endif

TARGET_GLOBAL_CFLAGS += \
			-msoft-float -fpic $(PIE_GLOBAL_CFLAGS) \
=======
$(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS += \
			-msoft-float \
>>>>>>> android-5.0.0_r2
			-ffunction-sections \
			-fdata-sections \
			-funwind-tables \
			-fstack-protector \
			-Wa,--noexecstack \
			-Werror=format-security \
			-D_FORTIFY_SOURCE=0 \
			-fstrict-aliasing \
			-fno-short-enums \
<<<<<<< HEAD
			-pipe \
			-no-canonical-prefixes $(NO_CANONICAL_SYSTEM_HEADERS)\
=======
			-no-canonical-prefixes \
			-fno-canonical-system-headers \
>>>>>>> android-5.0.0_r2
			$(arch_variant_cflags) \
			-include $(android_config_h) \
			-I $(dir $(android_config_h)) \
			$(STRICT_ALIASING_WARNINGS) $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)

TARGET_GLOBAL_CPPFLAGS += \
			$(arch_variant_cflags)

android_config_h := $(call select-android-config-h,linux-arm)
TARGET_ANDROID_CONFIG_CFLAGS := -include $(android_config_h) -I $(dir $(android_config_h))
TARGET_GLOBAL_CFLAGS += $(TARGET_ANDROID_CONFIG_CFLAGS)

<<<<<<< HEAD
# This warning causes dalvik not to build with gcc 4.6+ and -Werror.
# We cannot turn it off blindly since the option is not available
# in gcc-4.4.x.  We also want to disable sincos optimization globally
# by turning off the builtin sin function.
ifneq ($(filter 4.6 4.6.% 4.7 4.7.% 4.8 4.8.% 4.9 4.9.%, $(shell $(TARGET_CC) --version)),)
TARGET_GLOBAL_CFLAGS += -Wno-unused-but-set-variable -fno-builtin-sin \
=======
# The "-Wunused-but-set-variable" option often breaks projects that enable
# "-Wall -Werror" due to a commom idiom "ALOGV(mesg)" where ALOGV is turned
# into no-op in some builds while mesg is defined earlier. So we explicitly
# disable "-Wunused-but-set-variable" here.
ifneq ($(filter 4.6 4.6.% 4.7 4.7.% 4.8, $($(combo_2nd_arch_prefix)TARGET_GCC_VERSION)),)
$(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS += -fno-builtin-sin \
>>>>>>> android-5.0.0_r2
			-fno-strict-volatile-bitfields
ifneq ($(filter 4.8 4.8.% 4.9 4.9.%, $(shell $(TARGET_CC) --version)),)
gcc_variant_ldflags := \
			-Wl,--enable-new-dtags
else
gcc_variant_ldflags := \
			-Wl,--icf=safe
endif
endif

# This is to avoid the dreaded warning compiler message:
#   note: the mangling of 'va_list' has changed in GCC 4.4
#
# The fact that the mangling changed does not affect the NDK ABI
# very fortunately (since none of the exposed APIs used va_list
# in their exported C++ functions). Also, GCC 4.5 has already
# removed the warning from the compiler.
#
$(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS += -Wno-psabi

$(combo_2nd_arch_prefix)TARGET_GLOBAL_LDFLAGS += \
			-Wl,-z,noexecstack \
			-Wl,-z,relro \
			-Wl,-z,now \
			-Wl,--warn-shared-textrel \
			-Wl,--fatal-warnings \
			$(arch_variant_ldflags) $(gcc_variant_ldflags)

<<<<<<< HEAD
ifeq ($(TARGET_CLANG_VERSION),msm-%)
	TARGET_GLOBAL_LDFLAGS += \
	    -no-canonical-prefixes
endif

# more always true garglemesh:
TARGET_GLOBAL_CFLAGS += -mthumb-interwork
TARGET_GLOBAL_CPPFLAGS += -fvisibility-inlines-hidden

# More flags/options can be added here
TARGET_RELEASE_CFLAGS += \
=======
$(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS += -mthumb-interwork

$(combo_2nd_arch_prefix)TARGET_GLOBAL_CPPFLAGS += -fvisibility-inlines-hidden

# More flags/options can be added here
$(combo_2nd_arch_prefix)TARGET_RELEASE_CFLAGS := \
>>>>>>> android-5.0.0_r2
			-DNDEBUG \
                        -g \
			-fgcse-after-reload \
			-frerun-cse-after-loop \
			-frename-registers \
			-pipe $(DEBUG_SYMBOL_FLAGS) $(DEBUG_FRAME_POINTER_FLAGS)
libc_root := bionic/libc
libm_root := bionic/libm
libstdc++_root := bionic/libstdc++


## on some hosts, the target cross-compiler is not available so do not run this command
ifneq ($(wildcard $($(combo_2nd_arch_prefix)TARGET_CC)),)
# We compile with the global cflags to ensure that
# any flags which affect libgcc are correctly taken
# into account.
$(combo_2nd_arch_prefix)TARGET_LIBGCC := $(shell $($(combo_2nd_arch_prefix)TARGET_CC) \
        $($(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS) -print-libgcc-file-name)
$(combo_2nd_arch_prefix)TARGET_LIBATOMIC := $(shell $($(combo_2nd_arch_prefix)TARGET_CC) \
        $($(combo_2nd_arch_prefix)TARGET_GLOBAL_CFLAGS) -print-file-name=libatomic.a)
endif

<<<<<<< HEAD
# Define LTO (Link Time Optimization options)

ifeq ($(strip $(TARGET_ENABLE_LTO)),true)
# Enable global LTO if TARGET_ENABLE_LTO is set.
TARGET_LTO_CFLAGS := -flto \
                    -fno-toplevel-reorder \
                    -fno-section-anchors \
                    -flto-compression-level=5 \
                    -fuse-linker-plugin
endif

# Define FDO (Feedback Directed Optimization) options.

TARGET_FDO_CFLAGS:=
TARGET_FDO_LIB:=

ifneq ($(strip $(BUILD_FDO_INSTRUMENT)),)
  # Set BUILD_FDO_INSTRUMENT=true to turn on FDO instrumentation.
  # The profile will be generated on /data/local/tmp/profile on the device.
  TARGET_FDO_CFLAGS := -fprofile-generate=/data/local/tmp/profile -DANDROID_FDO
  TARGET_FDO_LIB := $(target_libgcov)
else
  # If BUILD_FDO_INSTRUMENT is turned off, then consider doing the FDO optimizations.
  # Set TARGET_FDO_PROFILE_PATH to set a custom profile directory for your build.
  ifeq ($(strip $(TARGET_FDO_PROFILE_PATH)),)
    TARGET_FDO_PROFILE_PATH := fdo/profiles/$(TARGET_ARCH)/$(TARGET_ARCH_VARIANT)
  else
    ifeq ($(strip $(wildcard $(TARGET_FDO_PROFILE_PATH))),)
      $(warning Custom TARGET_FDO_PROFILE_PATH supplied, but directory does not exist. Turn off FDO.)
    endif
  endif

  # If the FDO profile directory can't be found, then FDO is off.
  ifneq ($(strip $(wildcard $(TARGET_FDO_PROFILE_PATH))),)
    TARGET_FDO_CFLAGS := -fprofile-use=$(TARGET_FDO_PROFILE_PATH) -DANDROID_FDO
    TARGET_FDO_LIB := $(target_libgcov)
  endif
endif


# unless CUSTOM_KERNEL_HEADERS is defined, we're going to use
# symlinks located in out/ to point to the appropriate kernel
# headers. see 'config/kernel_headers.make' for more details
#
ifneq ($(CUSTOM_KERNEL_HEADERS),)
    KERNEL_HEADERS_COMMON := $(CUSTOM_KERNEL_HEADERS)
    KERNEL_HEADERS_ARCH   := $(CUSTOM_KERNEL_HEADERS)
else
    KERNEL_HEADERS_COMMON := $(libc_root)/kernel/common
    KERNEL_HEADERS_ARCH   := $(libc_root)/kernel/arch-$(TARGET_ARCH)
endif
=======
KERNEL_HEADERS_COMMON := $(libc_root)/kernel/uapi
KERNEL_HEADERS_ARCH   := $(libc_root)/kernel/uapi/asm-$(TARGET_$(combo_2nd_arch_prefix)ARCH)
>>>>>>> android-5.0.0_r2
KERNEL_HEADERS := $(KERNEL_HEADERS_COMMON) $(KERNEL_HEADERS_ARCH)

$(combo_2nd_arch_prefix)TARGET_C_INCLUDES := \
	$(libc_root)/arch-arm/include \
	$(libc_root)/include \
	$(libstdc++_root)/include \
	$(KERNEL_HEADERS) \
	$(libm_root)/include \
	$(libm_root)/include/arm \

$(combo_2nd_arch_prefix)TARGET_CRTBEGIN_STATIC_O := $($(combo_2nd_arch_prefix)TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtbegin_static.o
$(combo_2nd_arch_prefix)TARGET_CRTBEGIN_DYNAMIC_O := $($(combo_2nd_arch_prefix)TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtbegin_dynamic.o
$(combo_2nd_arch_prefix)TARGET_CRTEND_O := $($(combo_2nd_arch_prefix)TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtend_android.o

$(combo_2nd_arch_prefix)TARGET_CRTBEGIN_SO_O := $($(combo_2nd_arch_prefix)TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtbegin_so.o
$(combo_2nd_arch_prefix)TARGET_CRTEND_SO_O := $($(combo_2nd_arch_prefix)TARGET_OUT_INTERMEDIATE_LIBRARIES)/crtend_so.o

$(combo_2nd_arch_prefix)TARGET_STRIP_MODULE:=true

$(combo_2nd_arch_prefix)TARGET_DEFAULT_SYSTEM_SHARED_LIBRARIES := libc libstdc++ libm

$(combo_2nd_arch_prefix)TARGET_CUSTOM_LD_COMMAND := true

define $(combo_2nd_arch_prefix)transform-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
	-nostdlib -Wl,-soname,$(notdir $@) \
	-Wl,--gc-sections \
	$(if $(filter true,$(PRIVATE_CLANG)),-shared,-Wl,-shared) \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_SO_O)) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(TARGET_BUILD_APPS),$(PRIVATE_TARGET_LIBGCC)) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_SO_O)) \
	$(PRIVATE_LDLIBS)
endef

<<<<<<< HEAD
define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bdynamic $(PIE_EXECUTABLE_TRANSFORM) \
=======
define $(combo_2nd_arch_prefix)transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bdynamic -pie \
>>>>>>> android-5.0.0_r2
	-Wl,-dynamic-linker,/system/bin/linker \
	-Wl,--gc-sections \
	-Wl,-z,nocopyreloc \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	-Wl,-rpath-link=$(PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES) \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O)) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(TARGET_BUILD_APPS),$(PRIVATE_TARGET_LIBGCC)) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O)) \
	$(PRIVATE_LDLIBS)
endef

define $(combo_2nd_arch_prefix)transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) -nostdlib -Bstatic \
	-Wl,--gc-sections \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTBEGIN_STATIC_O)) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(call normalize-target-libraries,$(filter-out %libc_nomalloc.a,$(filter-out %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES)))) \
	-Wl,--start-group \
	$(call normalize-target-libraries,$(filter %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
	$(call normalize-target-libraries,$(filter %libc_nomalloc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(if $(PRIVATE_LIBCXX),,$(PRIVATE_TARGET_LIBGCC)) \
	-Wl,--end-group \
	$(if $(filter true,$(PRIVATE_NO_CRT)),,$(PRIVATE_TARGET_CRTEND_O))
endef
