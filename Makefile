TARGET := iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IGFloatingTabBar

IGFloatingTabBar_FILES = Tweak.xm
IGFloatingTabBar_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk

