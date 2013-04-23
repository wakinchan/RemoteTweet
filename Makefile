ARCHS = armv7
THEOS_INSTALL_KILL = Remote
THEOS_DEVICE_IP = 192.168.1.106
TARGET = iphone:clang::4.0

include theos/makefiles/common.mk

TWEAK_NAME = RemoteTweet
RemoteTweet_FILES = Tweak.xm
RemoteTweet_FRAMEWORKS = UIKit Social

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = RemoteTweetSettings
RemoteTweetSettings_FILES = Preference.m
RemoteTweetSettings_INSTALL_PATH = /Library/PreferenceBundles
RemoteTweetSettings_FRAMEWORKS = UIKit
RemoteTweetSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RemoteTweet.plist$(ECHO_END)
