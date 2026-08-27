TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = IGFloatingTabBarPrefs

IGFloatingTabBarPrefs_FILES = IGFTRootListController.m
IGFloatingTabBarPrefs_FRAMEWORKS = UIKit
IGFloatingTabBarPrefs_PRIVATE_FRAMEWORKS = Preferences
IGFloatingTabBarPrefs_INSTALL_PATH = /Library/PreferenceBundles
IGFloatingTabBarPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
