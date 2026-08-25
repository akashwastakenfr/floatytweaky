TARGET := iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IGFloatingTabBar

IGFloatingTabBar_FILES = Tweak.xm
IGFloatingTabBar_CFLAGS = -fobjc-arc
IGFloatingTabBar_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS)/makefiles/tweak.mk
SUBPROJECTS += igfloatingtabbarprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
