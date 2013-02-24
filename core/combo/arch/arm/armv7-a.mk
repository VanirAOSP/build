# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher
#
ARCH_ARM_HAVE_CLZ               := true
ARCH_ARM_HAVE_FFS               := true
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true

# Note: Hard coding the 'tune' value here is probably not ideal,
# and a better solution should be found in the future.
#
arch_variant_cflags := \
    -march=armv7-a \
    -mfloat-abi=softfp \
    -mfpu=vfpv3-d16

ifneq (,$(findstring cpu=cortex-a9,$(TARGET_EXTRA_CFLAGS)))
arch_variant_ldflags := \
	-Wl,--no-fix-cortex-a8
else
arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
endif

ifneq ($(strip $(TARGET_ARCH_VARIANT_CPU)),)
arch_variant_cflags += \
    -mtune=$(strip $(TARGET_ARCH_VARIANT_CPU))
endif
