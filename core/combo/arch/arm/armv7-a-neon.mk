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
ifneq (,$(filter cortex-a15 krait,$(TARGET_CPU_VARIANT)))
	cpu_for_optimizations := cortex-a15
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a9)
	cpu_for_optimizations := cortex-a9
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a8)
	cpu_for_optimizations := cortex-a8
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a7)
 	cpu_for_optimizations := cortex-a7
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a5)
 	cpu_for_optimizations := cortex-a5
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
endif
endif #end of cpu stuff

ifneq ($(cpu_for_optimizations),armv7-a)
TARGET_ARCH_VARIANT_CPU := $(cpu_for_optimizations)
arch_variant_cflags += \
	-mcpu=$(cpu_for_optimizations) \
	-mtune=$(cpu_for_optimizations)
else
arch_variant_cflags += \
	-march=armv7-a
endif

#is an FPU explicitly defined?
ifneq ($(strip $(TARGET_ARCH_VARIANT_FPU)),)
	TARGET_ARCH_VARIANT_FPU := $(TARGET_ARCH_VARIANT_FPU)
else #no, so figure out if one is set based on TARGET_CPU_VARIANT
ifneq (,$(filter cortex-a15 cortex-a7 cortex-a5 krait,$(TARGET_CPU_VARIANT)))
        rec_fpu := neon-vfpv4
else
        rec_fpu := neon
endif
	TARGET_ARCH_VARIANT_FPU := $(rec_fpu)
endif # ifneq ($(strip $(TARGET_ARCH_VARIANT_FPU),)

#get rid of existing instances of -mfpu in TARGET_GLOBAL_CP*FLAGS
TARGET_GLOBAL_CFLAGS := $(filter-out -mfpu=%,$(TARGET_GLOBAL_CFLAGS))
TARGET_GLOBAL_CPPFLAGS := $(filter-out -mfpu=%,$(TARGET_GLOBAL_CPPFLAGS))
arch_variant_cflags += -mfpu=$(TARGET_ARCH_VARIANT_FPU)

#is a float-abi explicitly defined?
ifeq ($(strip $(TARGET_ARCH_VARIANT_FLOAT_ABI)),)
	#no, so figure out if one is set on the GLOBAL_CFLAGS
	currentfloatabi := $(strip $(filter -mfloat-abi=%,$(TARGET_GLOBAL_CFLAGS)))

	#if one is, then use that as ARCH_VARIANT_FLOAT_ABI
	ifneq ($(currentfloatabi),)
		TARGET_ARCH_VARIANT_FLOAT_ABI := $(strip $(subst -mfloat-abi=,,$(currentfloatabi)))
	else
		TARGET_ARCH_VARIANT_FLOAT_ABI := softfp
	endif # ifneq ($(currentfloatabi),)
endif # ifeq ($(strip $(TARGET_ARCH_VARIANT_FLOAT_ABI)),)

#get rid of existing instances of -mfloat-abi in TARGET_GLOBAL_CP*FLAGS
TARGET_GLOBAL_CFLAGS := $(filter-out -mfloat-abi=%,$(TARGET_GLOBAL_CFLAGS))
TARGET_GLOBAL_CPPFLAGS := $(filter-out -mfloat-abi=%,$(TARGET_GLOBAL_CPPFLAGS))
arch_variant_cflags += -mfloat-abi=$(TARGET_ARCH_VARIANT_FLOAT_ABI)

arch_variant_ldflags += \
	-Wl,--fix-cortex-a8

######################################
## SNAPDRAGON CLANG/LLVM 3.4
######################################
ifneq ($(TARGET_CLANG_VERSION),)
ifeq ($(filter-out msm-%,$(TARGET_CLANG_VERSION)),)
# krait specific clang optimizations
ifeq ($(TARGET_CPU_VARIANT),krait)
CLANG_MSM_EXTRA_CFLAGS += \
  -mtune=krait2 \
  -mcpu=krait2
endif
endif
endif
