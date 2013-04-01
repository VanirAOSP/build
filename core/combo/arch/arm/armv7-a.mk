# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher
#
ARCH_ARM_HAVE_CLZ               := true
ARCH_ARM_HAVE_FFS               := true
ARCH_ARM_HAVE_ARMV7A            := true
ifneq ($(strip $(TARGET_ARCH_VARIANT_FPU)),none)
ARCH_ARM_HAVE_VFP               := true
else
ARCH_ARM_HAVE_VFP               := false
endif
ifeq ($(ARCH_ARM_USE_D16),true)
ARCH_ARM_HAVE_VFP_D32           := false
else
ARCH_ARM_HAVE_VFP_D32           := true
endif
ifeq ($(strip $(TARGET_CPU_SMP)),true)
ARCH_ARM_HAVE_TLS_REGISTER      := true
endif

# Note: Hard coding the 'arch' value here is probably not ideal,
# and a better solution should be found in the future.
#
arch_variant_cflags := \
    -march=armv7-a \
    -mtune=$(TARGET_ARCH_VARIANT_CPU)

ifneq (,$(findstring cpu=cortex-a9,$(TARGET_EXTRA_CFLAGS)))
arch_variant_ldflags += \
	-Wl,--no-fix-cortex-a8
else
arch_variant_ldflags += \
	-Wl,--fix-cortex-a8
endif

# if fpu is defined but not set use softfp and set fpu
ifeq ($(strip $(ARCH_ARM_HAVE_VFP)),true)
arch_variant_cflags += \
  -mfloat-abi=softfp \
  -mfpu=$(strip $(TARGET_ARCH_VARIANT_FPU))
else
# fall back on soft tunning if fpu is not specified
arch_variant_cflags += \
  -mfloat-abi=soft
endif
