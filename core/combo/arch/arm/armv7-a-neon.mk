# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#

ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true

# is arch variant CPU defined?
ifneq ($(strip $(TARGET_ARCH_VARIANT_CPU)),)

ifeq ($(strip $(TARGET_ARCH_VARIANT_CPU)),cortex-a15)
arch_cpu_without_ghosts := cortex-a9  #cortex-a15 has ghosts
else
arch_cpu_without_ghosts := $(strip $(TARGET_ARCH_VARIANT_CPU))
endif

arch_variant_cflags := \
	-mcpu=$(arch_cpu_without_ghosts) \
	-mtune=$(strip $(TARGET_ARCH_VARIANT_CPU))

else
arch_variant_cflags := \
        -march=armv7-a

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

ifneq (,$(findstring cpu=cortex-a9,$(TARGET_EXTRA_CFLAGS)))
arch_variant_ldflags := \
	-Wl,--no-fix-cortex-a8
else
arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
endif
