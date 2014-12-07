#
# Copyright (C) 2014 VanirAOSP && The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#  This config sets up an interface for toggling various build configurations
#  that can be set in device tree overlays.  All options should default off if
#  unset.  The vanir_config.mk is included in 
#  the following makefiles:
#	  $(BUILD_SYSTEM)/core/clang/config.mk
#    $(BUILD_SYSTEM)/core/combo/TARGET_linux-arm.mk
#    $(BUILD_SYSTEM)/binary.mk

# current build configurations:
# BONE_STOCK := set true to override all vanir_config variables
# NO_DEBUG_FRAME_POINTERS := set true to add frame pointers
# NO_DEBUG_SYMBOL_FLAGS := true removes debugging code insertions from assert.h macros and GDB
# MAXIMUM_OVERDRIVE := true disables address sanitizer, set in $(BUILD_SYSTEM)/core/clang/config.mk
# USE_GRAPHITE := true adds graphite cflags to turn on graphite
# USE_FSTRICT_FLAGS := true builds with fstrict-aliasing (thumb and arm)
# FSTRICT_ALIASING_WARNING_LEVEL := 0-3 for what is considered an aliasing violation

# set configurations here:
MAXIMUM_OVERDRIVE       +=
NO_DEBUG_SYMBOL_FLAGS   += true
NO_DEBUG_FRAME_POINTERS += true
USE_GRAPHITE            +=
USE_FSTRICT_FLAGS       +=
FSTRICT_ALIASING_WARNING_LEVEL += 2

# BONE_STOCK: strictly enforce AOSP defaults.
ifeq ($(BONE_STOCK),true)
  MAXIUMUM_OVERDRIVE      :=
  NO_DEBUG_SYMBOL_FLAGS   :=
  NO_DEBUG_FRAME_POINTERS :=
  USE_GRAPHITE            :=
  USE_FSTRICT_FLAGS       :=
  FSTRICT_ALIASING_WARNING_LEVEL := 0
endif

# DEBUGGING OPTIONS
DEBUG_SYMBOL_FLAGS :=
DEBUG_FRAME_POINTER_FLAGS :=
ifeq ($(NO_DEBUG_SYMBOL_FLAGS),true)
  DEBUG_SYMBOL_FLAGS += -g0 -DNDEBUG
endif
ifeq ($(NO_DEBUG_FRAME_POINTERS),true)
  DEBUG_FRAME_POINTER_FLAGS += -fomit-frame-pointer
endif

# GRAPHITE
GRAPHITE_FLAGS :=
ifeq ($(USE_GRAPHITE),true)
  GRAPHITE_FLAGS += \
          -fgraphite             \
          -floop-flatten         \
          -floop-parallelize-all \
          -ftree-loop-linear     \
          -floop-interchange     \
          -floop-strip-mine      \
          -floop-block
endif

# fstrict-aliasing
FSTRICT_FLAGS :=
ifeq ($USE_FSTRICT_FLAGS),true)
  FSTRICT_FLAGS += \
          -fstrict-aliasing       \
          -Wstrict-aliasing=$(FSTRICT_ALIASING_WARNING_LEVEL) \
          -Werror=strict-aliasing \
endif

# variables can be separated here for compiler compatibility.  They are inherited in their
# respective makefile locations.
VANIR_CLANG_OPTIONS  := \
        $(DEBUG_SYMBOL_FLAGS) \
        $(DEBUG_FRAME_POINTER_FLAGS)

VANIR_GCC_OPTIONS    := \
        $(DEBUG_SYMBOL_FLAGS) \
        $(DEBUG_FRAME_POINTER_FLAGS) \
        $(FSTRICT_FLAGS)

VANIR_BINARY_OPTIONS := \
        $(DEBUG_SYMBOL_FLAGS) \
        $(DEBUG_FRAME_POINTER_FLAGS) \
        $(GRAPHITE_FLAGS)
