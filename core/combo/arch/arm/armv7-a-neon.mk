# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_CLZ               := true
ARCH_ARM_HAVE_FFS               := true
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
# retain AOSP convention for ARCH_ARM_VFP_D32
# within build by appending to device tree to modify
ifeq ($(ARCH_ARM_USE_D16),true)
ARCH_ARM_HAVE_VFP_D32           := false
else
ARCH_ARM_HAVE_VFP_D32           := true
endif
ARCH_ARM_HAVE_NEON              := true
ifeq ($(strip $(TARGET_CPU_SMP)),true)
ARCH_ARM_HAVE_TLS_REGISTER      := true
endif

# define the defaults
arch_variant_cflags := \
     -mcpu=$(strip $(TARGET_ARCH_VARIANT_CPU)) \
     -mtune=$(strip $(TARGET_ARCH_VARIANT_CPU)) \
     -mfpu=neon \

# append more specific neon and fpu if defined
# todo: add more device specific soft/softfp/hard
ifneq ($(strip $(TARGET_ARCH_VARIANT_FPU)),)
arch_variant_cflags += \
     -mfloat-abi=softfp \
     -mfpu=$(strip $(TARGET_ARCH_VARIANT_FPU))
else
arch_variant_cflags += \
     -mfloat-abi=softfp
endif

ifeq ($(TARGET_ARCH_VARIANT_CPU),cortex-a9)
arch_variant_cflags += \
#    Remove -march=cortex-a15 until better support is provided. Not
#    entirely sure it's necessary anyways since -mcpu implies -march.
    -march=cortex-a9
endif
ifeq ($(TARGET_ARCH_VARIANT_CPU),cortex-a15)
arch_variant_cflags += \
#    Remove -march=cortex-a15 until better support is provided.
#    -march=cortex-a15
endif

ifneq (,$(findstring cpu=cortex-a9,$(TARGET_EXTRA_CFLAGS)))
arch_variant_ldflags := \
	-Wl,--no-fix-cortex-a8
else
arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
endif

#TODO: fine-tune generic values
ifeq ($(TARGET_ARCH_VARIANT_CPU),cortex-a15)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
#ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
ifeq ($(TARGET_ARCH_VARIANT_CPU),cortex-a9)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
ifeq ($(TARGET_ARCH_VARIANT_CPU),cortex-a8)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
