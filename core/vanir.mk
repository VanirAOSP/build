# Copyright (C) 2016 VanirAOSP
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
#

# STRICT #
ifeq ($(STRICT),true)
LOCAL_DISABLE_STRICT := \
	libc_bionic \
	libc_dns \
	libc_tzcode \
	libziparchive \
	libtwrpmtp \
	libfusetwrp \
	libguitwrp \
	busybox \
	libuclibcrpc \
	libziparchive-host \
	libpdfiumcore \
	libandroid_runtime \
	libmedia \
	libpdfiumcore \
	libpdfium \
	bluetooth.default \
	logd \
	mdnsd \
	net_net_gyp \
	libstagefright_webm \
	libaudioflinger \
	libmediaplayerservice \
	libstagefright \
	ping \
	ping6 \
	libdiskconfig \
	libjavacore \
	libfdlibm \
	libvariablespeed \
	librtp_jni \
	libwilhelm \
	libdownmix \
	libldnhncr \
	libqcomvisualizer \
	libvisualizer \
	libutils \
	libandroidfw \
	dnsmasq \
	static_busybox \
	libwebviewchromium \
	libwebviewchromium_loader \
	libwebviewchromium_plat_support \
	content_content_renderer_gyp \
	third_party_WebKit_Source_modules_modules_gyp \
	third_party_WebKit_Source_platform_blink_platform_gyp \
	third_party_WebKit_Source_core_webcore_remaining_gyp \
	third_party_angle_src_translator_lib_gyp \
	third_party_WebKit_Source_core_webcore_generated_gyp \
	libc_gdtoa \
	libc_openbsd \
	libc \
	libc_nomalloc \
	patchoat \
	dex2oat \
	libart \
	libart-compiler \
	oatdump \
	libart-disassembler \
	linker \
	libc_malloc \
	mdnsd \
	libstagefright_webm \
	libc_bionic_ndk \
	libc_dns \
	libc_gdtoa \
	libc_openbsd_ndk \
	liblog \
	libc \
	libbt-brcm_stack \
	libandroid_runtime \
	libandroidfw \
	libosi \
	libnetlink \
	clatd \
	ip \
	libc_nomalloc \
	linker \
	sensors.flounder \
	libnvvisualizer \
	libskia \
	libiprouteutil \
	libziparchive-host \
	libziparchive \
	libdiskconfig \
	logd \
	libjavacore \
	camera.msm8084 \
	libstagefright_webm \
	libc_bionic_ndk \
	libc_dns \
	libc_gdtoa \
	libc_openbsd_ndk \
	liblog \
	libc \
	libbt-brcm_stack \
	libandroid_runtime \
	libandroidfw \
	libosi \
	libnetlink \
	clatd \
	ip \
	libc_nomalloc \
	linker \
	libc_malloc \
	sensors.flounder \
	libnvvisualizer \
	libiprouteutil

DISABLE_STRICT := \
	-fno-strict-aliasing

STRICT_ALIASING_FLAGS := -fstrict-aliasing -Wno-error=strict-aliasing

STRICT_GCC_LEVEL := -Wstrict-aliasing=3

STRICT_CLANG_LEVEL := -Wstrict-aliasing=2
endif

ifeq ($(PIPE),true)
PIPE_FLAGS := -pipe 
endif
