# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_CLZ               := true
ARCH_ARM_HAVE_FFS               := true
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true


ifeq ($(strip $(TARGET_CPU_VARIANT)), cortex-a15)
	arch_variant_cflags := -mcpu=cortex-a15
else
	arch_variant_cflags := -march=armv7-a
endif

ifneq ($(strip $(TARGET_ARCH_VARIANT_CPU)),)
arch_variant_cflags += \
    -mtune=$(strip $(TARGET_ARCH_VARIANT_CPU))
endif

arch_variant_cflags += \
    -mfloat-abi=softfp \
    -mfpu=neon

ifneq (,$(findstring cpu=cortex-a9,$(TARGET_EXTRA_CFLAGS)))
arch_variant_ldflags := \
	-Wl,--no-fix-cortex-a8
else
arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
endif

#TODO: fine-tune generic values

ifeq ($(TARGET_ARCH_VARIANT_CPU), cortex-a15)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
#ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
ifeq ($(TARGET_ARCH_VARIANT_CPU), cortex-a9)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
ifeq ($(TARGET_ARCH_VARIANT_CPU), cortex-a8)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
