# We don't automatically set up rules to build packages for both
# TARGET_ARCH and TARGET_2ND_ARCH.
# To build it for TARGET_2ND_ARCH in a 64bit product, use "LOCAL_MULTILIB := 32".

my_prefix := TARGET_
include $(BUILD_SYSTEM)/multilib.mk

ifeq ($(TARGET_SUPPORTS_32_BIT_APPS)|$(TARGET_SUPPORTS_64_BIT_APPS),true|true)
  # packages default to building for either architecture,
  # the preferred if its supported, otherwise the non-preferred.
else ifeq ($(TARGET_SUPPORTS_64_BIT_APPS),true)
  # only 64-bit apps supported
  ifeq ($(filter $(my_module_multilib),64 both first),$(my_module_multilib))
    # if my_module_multilib was 64, both, first, or unset, build for 64-bit
    my_module_multilib := 64
  else
    # otherwise don't build this app
    my_module_multilib := none
  endif
else
<<<<<<< HEAD
$(LOCAL_INTERMEDIATE_TARGETS): \
    PRIVATE_DEFAULT_APP_TARGET_SDK := $(DEFAULT_APP_TARGET_SDK)
endif

ifneq ($(all_resources),)

# Since we don't know where the real R.java file is going to end up,
# we need to use another file to stand in its place.  We'll just
# copy the generated file to src/R.stamp, which means it will
# have the same contents and timestamp as the actual file.
#
# At the same time, this will copy the R.java file to a central
# 'R' directory to make it easier to add the files to an IDE.
#
#TODO: use PRIVATE_SOURCE_INTERMEDIATES_DIR instead of
#      $(intermediates.COMMON)/src
ifneq ($(package_expected_intermediates_COMMON),$(intermediates.COMMON))
  $(error $(LOCAL_MODULE): internal error: expected intermediates.COMMON "$(package_expected_intermediates_COMMON)" != intermediates.COMMON "$(intermediates.COMMON)")
endif

$(R_file_stamp): PRIVATE_RESOURCE_PUBLICS_OUTPUT := \
			$(intermediates.COMMON)/public_resources.xml
$(R_file_stamp): PRIVATE_PROGUARD_OPTIONS_FILE := $(proguard_options_file)
$(R_file_stamp): $(all_res_assets) $(full_android_manifest) $(RenderScript_file_stamp) $(AAPT) | $(ACP)
	@echo -e ${CL_YLW}"target R.java/Manifest.java:"${CL_RST}" $(PRIVATE_MODULE) ($@)"
	@rm -f $@
	$(create-resource-java-files)
	$(hide) for GENERATED_MANIFEST_FILE in `find $(PRIVATE_SOURCE_INTERMEDIATES_DIR) \
					-name Manifest.java 2> /dev/null`; do \
		dir=`awk '/package/{gsub(/\./,"/",$$2);gsub(/;/,"",$$2);print $$2;exit}' $$GENERATED_MANIFEST_FILE`; \
		mkdir -p $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
		$(ACP) -fp $$GENERATED_MANIFEST_FILE $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
	done;
	$(hide) for GENERATED_R_FILE in `find $(PRIVATE_SOURCE_INTERMEDIATES_DIR) \
					-name R.java 2> /dev/null`; do \
		dir=`awk '/package/{gsub(/\./,"/",$$2);gsub(/;/,"",$$2);print $$2;exit}' $$GENERATED_R_FILE`; \
		mkdir -p $(TARGET_COMMON_OUT_ROOT)/R/$$dir; \
		$(ACP) -fp $$GENERATED_R_FILE $(TARGET_COMMON_OUT_ROOT)/R/$$dir \
			|| exit 31; \
		$(ACP) -fp $$GENERATED_R_FILE $@ || exit 32; \
	done; \

$(proguard_options_file): $(R_file_stamp)

ifdef LOCAL_EXPORT_PACKAGE_RESOURCES
# Put this module's resources into a PRODUCT-agnositc package that
# other packages can use to build their own PRODUCT-agnostic R.java (etc.)
# files.
resource_export_package := $(intermediates.COMMON)/package-export.apk
$(R_file_stamp): $(resource_export_package)

# add-assets-to-package looks at PRODUCT_AAPT_CONFIG, but this target
# can't know anything about PRODUCT.  Clear it out just for this target.
$(resource_export_package): PRIVATE_PRODUCT_AAPT_CONFIG :=
$(resource_export_package): PRIVATE_PRODUCT_AAPT_PREF_CONFIG :=
$(resource_export_package): $(all_res_assets) $(full_android_manifest) $(RenderScript_file_stamp) $(AAPT)
	@echo -e ${CL_GRN}"target Export Resources:"${CL_RST}" $(PRIVATE_MODULE) ($@)"
	$(create-empty-package)
	$(add-assets-to-package)
endif

# Other modules should depend on the BUILT module if
# they want to use this module's R.java file.
$(LOCAL_BUILT_MODULE): $(R_file_stamp)

ifneq ($(full_classes_jar),)
# If full_classes_jar is non-empty, we're building sources.
# If we're building sources, the initial javac step (which
# produces full_classes_compiled_jar) needs to ensure the
# R.java and Manifest.java files have been generated first.
$(full_classes_compiled_jar): $(R_file_stamp)
endif

endif  # all_resources

ifeq ($(LOCAL_NO_STANDARD_LIBRARIES),true)
# We need to explicitly clear this var so that we don't
# inherit the value from whomever caused us to be built.
$(LOCAL_INTERMEDIATE_TARGETS): PRIVATE_AAPT_INCLUDES :=
else
# Most packages should link against the resources defined by framework-res.
# Even if they don't have their own resources, they may use framework
# resources.
ifneq ($(filter-out current,$(LOCAL_SDK_RES_VERSION))$(if $(TARGET_BUILD_APPS),$(filter current,$(LOCAL_SDK_RES_VERSION))),)
# for released sdk versions, the platform resources were built into android.jar.
framework_res_package_export := \
    $(HISTORICAL_SDK_VERSIONS_ROOT)/$(LOCAL_SDK_RES_VERSION)/android.jar
framework_res_package_export_deps := $(framework_res_package_export)
else # LOCAL_SDK_RES_VERSION
framework_res_package_export := \
    $(call intermediates-dir-for,APPS,framework-res,,COMMON)/package-export.apk
# We can't depend directly on the export.apk file; it won't get its
# PRIVATE_ vars set up correctly if we do.  Instead, depend on the
# corresponding R.stamp file, which lists the export.apk as a dependency.
framework_res_package_export_deps := \
    $(dir $(framework_res_package_export))src/R.stamp
endif # LOCAL_SDK_RES_VERSION
$(R_file_stamp): $(framework_res_package_export_deps)
$(LOCAL_INTERMEDIATE_TARGETS): \
    PRIVATE_AAPT_INCLUDES := $(framework_res_package_export)
endif # LOCAL_NO_STANDARD_LIBRARIES

ifneq ($(full_classes_jar),)
$(LOCAL_BUILT_MODULE): PRIVATE_DEX_FILE := $(built_dex)
$(LOCAL_BUILT_MODULE): $(built_dex)
endif # full_classes_jar


# Get the list of jni libraries to be included in the apk file.

so_suffix := $($(my_prefix)SHLIB_SUFFIX)

jni_shared_libraries := \
    $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
      $(addsuffix $(so_suffix), \
        $(LOCAL_JNI_SHARED_LIBRARIES)))

# Include RS dynamically-generated libraries as well
# Keep this ifneq, as the += otherwise adds spaces that need to be stripped.
ifneq ($(rs_compatibility_jni_libs),)
jni_shared_libraries += $(rs_compatibility_jni_libs)
endif

# App explicitly requires the prebuilt NDK libstlport_shared.so.
# libstlport_shared.so should never go to the system image.
# Instead it should be packaged into the apk.
ifeq (stlport_shared,$(LOCAL_NDK_STL_VARIANT))
ifndef LOCAL_SDK_VERSION
$(error LOCAL_SDK_VERSION has to be defined together with LOCAL_NDK_STL_VARIANT, \
    LOCAL_PACKAGE_NAME=$(LOCAL_PACKAGE_NAME))
endif
jni_shared_libraries += \
    $(HISTORICAL_NDK_VERSIONS_ROOT)/current/sources/cxx-stl/stlport/libs/$(TARGET_CPU_ABI)/libstlport_shared.so
=======
  # only 32-bit apps supported
  ifeq ($(filter $(my_module_multilib),32 both),$(my_module_multilib))
    # if my_module_multilib was 32, both, or unset, build for 32-bit
    my_module_multilib := 32
  else ifeq ($(my_module_multilib),first)
    ifndef TARGET_IS_64_BIT
      # if my_module_multilib was first and this is a 32-bit build, build for
      # 32-bit
      my_module_multilib := 32
    else
      # if my_module_multilib was first and this is a 64-bit build, don't build
      # this app
      my_module_multilib := none
    endif
  else
    # my_module_mulitlib was 64 or none, don't build this app
    my_module_multilib := none
  endif
>>>>>>> android-5.0.0_r2
endif

LOCAL_NO_2ND_ARCH_MODULE_SUFFIX := true

# if TARGET_PREFER_32_BIT_APPS is set, try to build 32-bit first
ifdef TARGET_2ND_ARCH
ifeq ($(TARGET_PREFER_32_BIT_APPS),true)
LOCAL_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
else
LOCAL_2ND_ARCH_VAR_PREFIX :=
endif
endif

# check if preferred arch is supported
include $(BUILD_SYSTEM)/module_arch_supported.mk
ifeq ($(my_module_arch_supported),true)
# first arch is supported
include $(BUILD_SYSTEM)/package_internal.mk
else ifneq (,$(TARGET_2ND_ARCH))
# check if the non-preferred arch is the primary or secondary
ifeq ($(TARGET_PREFER_32_BIT_APPS),true)
LOCAL_2ND_ARCH_VAR_PREFIX :=
else
<<<<<<< HEAD
    $(LOCAL_BUILT_MODULE): PRIVATE_PRODUCT_AAPT_CONFIG := $(PRODUCT_AAPT_CONFIG)
    $(LOCAL_BUILT_MODULE): PRIVATE_PRODUCT_AAPT_PREF_CONFIG := $(PRODUCT_AAPT_PREF_CONFIG)
endif
$(LOCAL_BUILT_MODULE): $(all_res_assets) $(jni_shared_libraries) $(full_android_manifest)
	@echo -e ${CL_GRN}"target Package:"${CL_RST}" $(PRIVATE_MODULE) ($@)"
	$(create-empty-package)
	$(add-assets-to-package)
ifneq ($(jni_shared_libraries),)
	$(add-jni-shared-libs-to-package)
=======
LOCAL_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
>>>>>>> android-5.0.0_r2
endif

# check if non-preferred arch is supported
include $(BUILD_SYSTEM)/module_arch_supported.mk
ifeq ($(my_module_arch_supported),true)
# secondary arch is supported
include $(BUILD_SYSTEM)/package_internal.mk
endif
endif # TARGET_2ND_ARCH

LOCAL_2ND_ARCH_VAR_PREFIX :=
LOCAL_NO_2ND_ARCH_MODULE_SUFFIX :=

my_module_arch_supported :=
