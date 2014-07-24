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
ifneq ($(TARGET_KERNEL_CUSTOM_TOOLCHAIN),)
TARGET_KERNEL_CUSTOM_TOOLCHAIN := linaro-4.7
endif

# mangling too support horendous nomenclature
ifeq ($(TARGET_KERNEL_CUSTOM_TOOLCHAIN),linaro-4.9)
    TARGET_KERNEL_CUSTOM_TOOLCHAIN_ALIAS := arm-eabi-
else
    TARGET_KERNEL_CUSTOM_TOOLCHAIN_ALIAS := arm-gnueabi-
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
    TOOL_PREFIX:=$(ANDROID_BUILD_TOP)/prebuilts/gcc/linux-x86/arm/linaro/$(T_K_C_T)-$(TARGET_KERNEL_CPU_VARIANT)/bin/$(TARGET_KERNEL_CUSTOM_TOOLCHAIN_ALIAS)
endif
