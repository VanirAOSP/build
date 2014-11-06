#
# Copyright (C) 2014 The Android Open Source Project
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

# Don't modify this file - It's just an alias!

<<<<<<< HEAD
PRODUCT_PACKAGES := \
	Calculator \
	DeskClock \
	Email \
	Exchange2 \
	FusedLocation \
	Gallery2 \
	Keyguard \
	Music \
	Mms \
	PrintSpooler \
	TeleService \
	SoftKeyboard \
	SystemUI \
	Launcher3 \
	Development \
	DevelopmentSettings \
	Fallback \
	Settings \
	SdkSetup \
	CustomLocale \
	sqlite3 \
	InputDevices \
	LatinIME \
	CertInstaller \
	LiveWallpapersPicker \
	ApiDemos \
	GestureBuilder \
	CubeLiveWallpapers \
	QuickSearchBox \
	WidgetPreview \
	librs_jni \
	ConnectivityTest \
	GpsLocationTest \
	CalendarProvider \
	Calendar \
	SmokeTest \
	SmokeTestApp \
	rild \
	LegacyCamera \
	Dialer
=======
$(call inherit-product, $(SRC_TARGET_DIR)/product/sdk_phone_armv7.mk)
>>>>>>> android-5.0.0_r2

PRODUCT_NAME := sdk
