#import <UIKit/UIKit.h>
#import <Twitter/TWTweetComposeViewController.h>
#import <Social/Social.h>
#import "Firmware.h"

#define M_ARTIST @"_ARTIST_"
#define M_SONG   @"_SONG_"
#define M_ALBUM  @"_ALBUM_"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.kindadev.RemoteTweet.plist"

static NSString *artist;
static NSString *song;
static NSString *album;
static UIImage *artwork;
static int choice;
static NSString *format;
UIViewController *viewController;

@interface MRNowPlayingScreen
@property(readonly) id titleView;
@property(retain) UIView * bottomBar;
@end

static inline void postFunction()
{
    NSString *cStr = [[NSString alloc] init];
    cStr = [format stringByReplacingOccurrencesOfString:M_ARTIST withString:artist];
    cStr = [cStr stringByReplacingOccurrencesOfString:M_SONG withString:song];
    cStr = [cStr stringByReplacingOccurrencesOfString:M_ALBUM withString:album];
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)cStr, NULL,  (CFStringRef)@"&=-#", kCFStringEncodingUTF8);

    if (choice == 0)
    {
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) {
            SLComposeViewController *twitterPostVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [twitterPostVC setInitialText:cStr];
            [twitterPostVC addImage:artwork];
            [viewController presentViewController:twitterPostVC animated:YES completion:nil];
        }
        else
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            [tweetViewController setInitialText:cStr];
            [tweetViewController addImage:artwork];
            tweetViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
                [viewController dismissModalViewControllerAnimated:YES];
            };
            [viewController presentModalViewController:tweetViewController animated:YES];
        }
    }
    else if (choice == 1 && kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
    {
        SLComposeViewController *facebookPostVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [facebookPostVC setInitialText:cStr];
        [facebookPostVC addImage:artwork];
        [viewController presentViewController:facebookPostVC animated:YES completion:nil];
    }
    else if (choice == 2 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///post?text=%@", encodedString]]];
    else if (choice == 3 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", encodedString]]];
    else if (choice == 4 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"echofon://"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"echofon:///message?%@", encodedString]]];
    else if (choice == 5 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"echofonpro://"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"echofonpro:///message?%@", encodedString]]];
    else if (choice == 6)
        [UIPasteboard generalPasteboard].string = encodedString;
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/home?status=%@", encodedString]]];
}

%hook MRNowPlayingScreen
- (void)viewDidLoad
{
	%orig;

	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [[self titleView] addGestureRecognizer:longPress];   
    [longPress release];

    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
    shareBtn.frame = CGRectMake(10, 34, 30, 30);
    [shareBtn addTarget:self action:@selector(btnTaped:) forControlEvents:UIControlEventTouchDown];
    [self.bottomBar addSubview:shareBtn];
}

%new(v@:@)
- (void)btnTaped:(UIButton *)sender
{
    postFunction();
}

%new(v@:@)
- (void)longPress:(UILongPressGestureRecognizer*)gesture 
{
    postFunction();
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

%hook MRNowPlayingFrontScreen
- (void)setArtworkImage:(id)arg1
{
    %orig;
    artwork = arg1;
}
%end

%hook MRiTunesInterface_iPhone
- (id)nowPlayingScreen
{
    id tmp = %orig;
    viewController = tmp;
    return tmp;
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

