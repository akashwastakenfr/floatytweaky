TARGET := iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AyorFloat

AyorFloat_FILES = Tweak.xm
AyorFloat_CFLAGS = -fobjc-arc
AyorFloat_FRAMEWORKS = UIKit CoreGraphics
AyorFloat_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS)/makefiles/tweak.mk
