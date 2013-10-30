# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true

# is arch variant CPU defined?
ifneq ($(strip $(TARGET_ARCH_VARIANT_CPU)),)
	cpu_for_optimizations := $(strip $(TARGET_ARCH_VARIANT_CPU))
else
# infer TARGET_ARCH_VARIANT_CPU from TARGET_CPU_VARIANT
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a15)
	cpu_for_optimizations := cortex-a15
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a9)
	cpu_for_optimizations := cortex-a9
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a7)
	cpu_for_optimizations := cortex-a7
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),krait)
	cpu_for_optimizations := cortex-a9
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),scorpion)
	cpu_for_optimizations := cortex-a8
else
	cpu_for_optimizations := armv7-a
endif
endif
endif
endif
endif
endif #end of cpu stuff

ifneq ($(cpu_for_optimizations),armv7-a)
ifeq ($(cpu_for_optimizations),cortex-a15)
	arch_cpu_without_ghosts := cortex-a9  #cortex-a15 has ghosts
else
	arch_cpu_without_ghosts := $(cpu_for_optimizations)
endif
arch_variant_cflags := \
	-mcpu=$(arch_cpu_without_ghosts) \
	-mtune=$(cpu_for_optimizations)
else
arch_variant_cflags := \
	-march=armv7-a
endif

ifeq ($(strip $(TARGET_ARCH_VARIANT_FPU)),)
TARGET_ARCH_VARIANT_FPU := neon
endif
ifeq ($(strip $(filter-out -mfpu=%,$(TARGET_GLOBAL_CFLAGS))),$(strip $(TARGET_GLOBAL_CFLAGS)))
arch_variant_cflags += -mfpu=$(TARGET_ARCH_VARIANT_FPU)
endif
ifeq ($(strip $(filter-out -mfloat-abi=%,$(TARGET_GLOBAL_CFLAGS))),$(strip $(TARGET_GLOBAL_CFLAGS)))
arch_variant_cflags += -mfloat-abi=softfp
endif

arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
