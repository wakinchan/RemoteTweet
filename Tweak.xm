#import <UIKit/UIKit.h>

#define M_ARTIST @"_ARTIST_"
#define M_SONG   @"_SONG_"
#define M_ALBUM  @"_ALBUM_"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.kindadev.RemoteTweet.plist"

static NSString *artist;
static NSString *song;
static NSString *album;
static int choice;
static NSString *format;

@interface MRNowPlayingTitle : UIView
@end

@interface MRNowPlayingScreen
@property(readonly) MRNowPlayingTitle * titleView;
@end

%hook MRNowPlayingScreen

- (void)viewDidLoad
{
	%orig;

	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [[self titleView] addGestureRecognizer:longPress];   
    [longPress release];
}

%new(v@:@)
- (void)longPress:(UILongPressGestureRecognizer*)gesture 
{
	NSString *cStr = [format stringByReplacingOccurrencesOfString:M_ARTIST withString:artist];
    cStr = [cStr stringByReplacingOccurrencesOfString:M_SONG withString:song];
    cStr = [cStr stringByReplacingOccurrencesOfString:M_ALBUM withString:album];

	NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)cStr, NULL,  (CFStringRef)@"&=-#", kCFStringEncodingUTF8);

	if (choice == 0 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///post?text=%@", encodedString]]];
	else if (choice == 1 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", encodedString]]];
	else if (choice == 2 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"echofon://"]])
    	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"echofon:///message?%@", encodedString]]];
	else if (choice == 3 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"echofonpro://"]])
    	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"echofonpro:///message?%@", encodedString]]];
    else if (choice == 4)
       	[UIPasteboard generalPasteboard].string = encodedString;
    else
       	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/home?status=%@", encodedString]]];
}

%end

%hook MRNowPlayingTitle

- (void)layoutLabels
{
	%orig;

	artist = MSHookIvar<UILabel *>(self, "_artist").text;
	song = MSHookIvar<UILabel *>(self, "_song").text;
	album = MSHookIvar<UILabel *>(self, "_album").text;
}

%end

static void LoadSettings()
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	id choicePref = [dict objectForKey:@"choice"];
	choice = choicePref ? [choicePref intValue] : 0;
    id formatPref = [dict objectForKey:@"Format"];
    format = formatPref ? [formatPref copy] : @"_ARTIST_ - _SONG_ (_ALBUM_) #NowPlaying";
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadSettings();
}

%ctor
{
    @autoreleasepool {
        %init;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.kindadev.RemoteTweet.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
    }
}

