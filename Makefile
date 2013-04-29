THEOS_INSTALL_KILL = Remote
THEOS_DEVICE_IP = 192.168.1.101
TARGET = iphone:clang::5.0
GO_EASY_ON_ME=1

include theos/makefiles/common.mk

TWEAK_NAME = RemoteTweet
RemoteTweet_FILES = Tweak.xm
RemoteTweet_FRAMEWORKS = UIKit
RemoteTweet_LDFLAGS = -weak_framework Twitter -weak_framework Social

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

real-clean:
	rm -rf _
	rm -rf .obj
	rm -rf .theos
	rm -rf *.deb
