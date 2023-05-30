TARGET := iphone:clang:14.5:12.2
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_USE_NEW_ABI=1

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = VBModule
VBModule_BUNDLE_EXTENSION = bundle
VBModule_FILES = VBModule.m
VBModule_CFLAGS = -fobjc-arc
VBModule_FRAMEWORKS = UIKit
VBModule_PRIVATE_FRAMEWORKS = ControlCenterUIKit MobileCoreServices
VBModule_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS_MAKE_PATH)/bundle.mk
