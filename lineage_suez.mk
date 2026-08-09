#
# Copyright (C) 2017 The LineageOS Project
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

# Inherit some common Lineage stuff.
$(call inherit-product-if-exists, vendor/lineage/config/common_full_tablet_wifionly.mk)

# Inherit from the common Open Source product configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_l_mr1.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Inherit from hardware-specific part of the product configuration
$(call inherit-product, device/amazon/suez/device.mk)

# Product Charateristics
PRODUCT_CHARACTERISTICS := tablet

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := lineage_suez
PRODUCT_DEVICE := suez
PRODUCT_BRAND := google
PRODUCT_MODEL := Fire
# suez: matches ro.product.manufacturer from a reference suez build.prop
# (system_dump/suez) that impersonates genuine Amazon Fire identity -- some
# Amazon-integrated apps (Prime Video's Fovea SDK in particular, gating
# hardware-accelerated/full-HD playback) key off this to recognize actual
# Fire hardware. Was "Google", which doesn't match any real Amazon device
# and reads as unrecognized/unsupported hardware to such checks.
PRODUCT_MANUFACTURER := amzn

# suez: same reference suez build.prop (system_dump/suez) sets PRODUCT_BRAND
# to "google" (kept as-is above -- needed for GMS/Play Integrity, untouched)
# but overrides the *build fingerprint string* separately to start with
# "Amazon" instead of "google". Only Amazon-facing app checks (again, Prime
# Video's Fovea SDK) parse this string; GMS certification keys off the
# actual ro.product.brand/model/manufacturer properties, which are
# unaffected by this override. Real Android 11 version/build info is kept
# accurate (via lazy `=` expansion, not hardcoded) so this doesn't go stale
# or become internally inconsistent with Build.VERSION.* -- only the brand
# token changes from the default computed fingerprint.
# Note: BUILD_NUMBER itself is obsolete (build/make/core/main.mk marks it via
# KATI_obsolete_var once config.mk has run). BUILD_NUMBER_FROM_FILE isn't a
# safe substitute here either -- its value is the literal text "$(cat
# .../build_number.txt)", meant to be handed to a shell in a recipe context,
# not re-expanded by make itself. Since this whole fingerprint is a
# recursively-expanded (`=`) variable, kati re-parses it on every reference,
# and stumbles trying to interpret that embedded "$(cat ...)" as its own
# syntax ("unterminated variable reference"). Use $(file <...), same as
# BF_BUILD_NUMBER's own computation in build/make/core/Makefile, which reads
# the file's actual contents immediately and inserts inert text instead.
BUILD_FINGERPRINT = Amazon/$(TARGET_PRODUCT)/$(TARGET_DEVICE):$(PLATFORM_VERSION)/$(BUILD_ID)/$(file <$(BUILD_NUMBER_FILE)):$(TARGET_BUILD_VARIANT)/$(BUILD_VERSION_TAGS)

PRODUCT_GMS_CLIENTID_BASE := android-google
