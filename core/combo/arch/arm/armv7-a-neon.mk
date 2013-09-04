# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#

TARGET_ARCH_VARIANT_FPU := neon
include $(BUILD_COMBOS)/arch/$(TARGET_ARCH)/armv7-a.mk

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

# is arch variant CPU defined?
ifneq ($(strip $(TARGET_ARCH_VARIANT_CPU)),)

ifeq ($(strip $(TARGET_ARCH_VARIANT_CPU)),cortex-a15)
arch_cpu_without_ghosts := cortex-a9  #cortex-a15 has ghosts
else
arch_cpu_without_ghosts := $(strip $(TARGET_ARCH_VARIANT_CPU))
endif

arch_variant_cflags += \
	-mcpu=$(arch_cpu_without_ghosts) \
	-mtune=$(strip $(TARGET_ARCH_VARIANT_CPU))

else

$(warn TARGET_ARCH_VARIANT_CPU is NOT SET! Using values from armv7-a.mk)

endif #end of cpu stuff

ifneq ($(strip $(TARGET_ARCH_VARIANT_FPU)),)
arch_variant_cflags += \
	-mfloat-abi=softfp \
	-mfpu=$(strip $(TARGET_ARCH_VARIANT_FPU))
else
# fall back on soft tunning if fpu is not specified
arch_variant_cflags += \
	-mfloat-abi=soft
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
ifeq ($(TARGET_ARCH_VARIANT_CPU), cortex-a5)
ARCH_ARM_HAVE_NEON_UNALIGNED_ACCESS    := true
ARCH_ARM_NEON_MEMSET_DIVIDER           := 132
ARCH_ARM_NEON_MEMCPY_ALIGNMENT_DIVIDER := 224
endif
