TARGET := iphone:clang:14.5:13.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES := MobileGestaltHelper

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME := libAltSpringBoardServices

libAltSpringBoardServices_FILES += AltSpringBoardServices.mm
libAltSpringBoardServices_FILES += springboard.m
springboard.m_CFLAGS += -fno-objc-arc
libAltSpringBoardServices_CFLAGS += -fobjc-arc
libAltSpringBoardServices_CFLAGS += -Iinclude
libAltSpringBoardServices_CFLAGS += -DJB_PREFIX=\"/var/jb\"
libAltSpringBoardServices_CCFLAGS += -std=c++14
libAltSpringBoardServices_LDFLAGS += -Wl,-no_warn_inits
libAltSpringBoardServices_LIBRARIES += rocketbootstrap
libAltSpringBoardServices_INSTALL_PATH = /usr/lib

include $(THEOS_MAKE_PATH)/library.mk