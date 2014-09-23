# sweater-vest compat
ifeq ($(HOST_OS),darwin)
  MAKE_FLAGS := C_INCLUDE_PATH=$(ANDROID_BUILD_TOP)/external/elfutils/libelf
  TARGET_KERNEL_USE_AOSP_TOOLCHAIN := true
endif

ifneq ($(strip $(BONE_STOCK)),)
  TARGET_KERNEL_USE_AOSP_TOOLCHAIN := true
endif

# sideways compat
ifeq ($(USE_AOSP_TOOLCHAINS),true)
    TARGET_KERNEL_USE_AOSP_TOOLCHAIN := true
endif

# default
ifeq ($(TARGET_KERNEL_CUSTOM_TOOLCHAIN),)
    TARGET_KERNEL_CUSTOM_TOOLCHAIN := linaro-4.7
endif

# allow setting the cpu variant for unsupported cpu's like cortex-a7
ifeq ($(TARGET_KERNEL_CPU_VARIANT),)
    TARGET_KERNEL_CPU_VARIANT := $(cpu_for_optimizations)
else
    TARGET_KERNEL_CPU_VARIANT := $(TARGET_KERNEL_CPU_VARIANT)
endif

# meat and potatoes
ifeq ($(TARGET_KERNEL_USE_AOSP_TOOLCHAIN),true)
    ifneq ($(TARGET_KERNEL_CUSTOM_AOSP_TOOLCHAIN),)
        TARGET_KERNEL_CUSTOM_TOOLCHAIN:=$(TARGET_KERNEL_CUSTOM_AOSP_TOOLCHAIN)
    else
        TARGET_KERNEL_CUSTOM_TOOLCHAIN:=arm-eabi-4.7
    endif

    TOOL_PREFIX:=$(ANDROID_BUILD_TOP)/prebuilts/gcc/$(HOST_PREBUILT_TAG)/arm/$(TARGET_KERNEL_CUSTOM_TOOLCHAIN)/bin/arm-eabi-
else
    T_K_C_T_STRIPPER := $(shell echo $(TARGET_KERNEL_CUSTOM_TOOLCHAIN) | sed -e 's/[a-z]//g')
    T_K_C_T_DASHER := $(shell echo $(T_K_C_T_STRIPPER) | sed -e 's/-//g')
    T_K_C_T := linaro-$(T_K_C_T_DASHER)

    # prefix auto-determination. hollah for a dollah.
    POSSIBLE_TOOLCHAIN_PREFIXES := arm-eabi- arm-gnueabi- arm-gnueabihf-

    TOOL_PREFIX := $(patsubst %-gcc,%-,$(firstword $(foreach var, $(POSSIBLE_TOOLCHAIN_PREFIXES), $(wildcard $(ANDROID_BUILD_TOP)/prebuilts/gcc/linux-x86/arm/linaro/$(T_K_C_T)-$(TARGET_KERNEL_CPU_VARIANT)/bin/$(var)gcc))))
endif
