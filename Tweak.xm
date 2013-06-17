#import <UIKit/UIKit.h>
#import <Twitter/TWTweetComposeViewController.h>
#import <Social/Social.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CommonCrypto/CommonDigest.h>

#define M_ARTIST @"_ARTIST_"
#define M_SONG   @"_SONG_"
#define M_ALBUM  @"_ALBUM_"
#define PREF_PATH @"/var/mobile/Library/Preferences/com.kindadev.RemoteTweet.plist"
#define MISSING_MD5 @"d70f15fef16c1b2c838df6e29984e831"

#ifndef kCFCoreFoundationVersionNumber_iOS_5_0
#define kCFCoreFoundationVersionNumber_iOS_5_0 675.00
#endif
#ifndef kCFCoreFoundationVersionNumber_iOS_6_0
#define kCFCoreFoundationVersionNumber_iOS_6_0 793.00
#endif

static NSString *artist;
static NSString *song;
static NSString *album;
static UIImage *artwork;
static int choice;
static NSString *format;
static NSString *formatPad;
static BOOL isArtworkEnabled;
static UIViewController *viewController;

static inline BOOL IsPad();
static inline NSString* ConvertFormat();
static inline void PostFunction();
static inline NSString * MD5String(UIImage *image);

static inline BOOL IsPad()
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

static inline NSString* ConvertFormat()
{
    NSString *cStr = [[NSString alloc] init];
    if (IsPad())
    {
        cStr = [formatPad stringByReplacingOccurrencesOfString:M_ARTIST withString:artist];
        cStr = [cStr stringByReplacingOccurrencesOfString:M_SONG withString:song];
    }
    else
    {        
        cStr = [format stringByReplacingOccurrencesOfString:M_ARTIST withString:artist];
        cStr = [cStr stringByReplacingOccurrencesOfString:M_SONG withString:song];
        cStr = [cStr stringByReplacingOccurrencesOfString:M_ALBUM withString:album];
    }
    return cStr;
}

static inline void PostFunction()
{
    NSString *cStr = ConvertFormat();
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)cStr, NULL,  (CFStringRef)@"&=-#", kCFStringEncodingUTF8);

    if (choice == 0 && kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0)
    {
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) {
            SLComposeViewController *twitterPostVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [twitterPostVC setInitialText:cStr];
            if (isArtworkEnabled && ![MD5String(artwork) isEqualToString:MISSING_MD5])
                [twitterPostVC addImage:artwork];
            [viewController presentViewController:twitterPostVC animated:YES completion:nil];
        }
        else
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            [tweetViewController setInitialText:cStr];
            if (isArtworkEnabled && ![MD5String(artwork) isEqualToString:MISSING_MD5])
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
        if (isArtworkEnabled && ![MD5String(artwork) isEqualToString:MISSING_MD5])
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
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/intent/tweet?text=%@", encodedString]]];
}

static inline NSString * MD5String(UIImage *image)
{
    unsigned char hash[16];
    CGDataProviderRef dataProvider;
    NSData* data;
    dataProvider = CGImageGetDataProvider(image.CGImage);
    data = (NSData*)CFDataCreateMutableCopy(NULL, 0, CGDataProviderCopyData(dataProvider));
    CC_MD5([data bytes], [data length], hash);
    return [NSString stringWithFormat:
        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        hash[0], hash[1], hash[2], hash[3], 
        hash[4], hash[5], hash[6], hash[7],
        hash[8], hash[9], hash[10], hash[11],
        hash[12], hash[13], hash[14], hash[15]
        ];
}

@interface MRNowPlayingScreen
@property(readonly) id titleView;
@property(retain) UIView * bottomBar;
@end

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
    PostFunction();
}

%new(v@:@)
- (void)longPress:(UILongPressGestureRecognizer *)gesture 
{
    PostFunction();
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

%hook MRPlayerScreen_iPad
- (void)viewDidLoad
{
    %orig;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    UIView *view = MSHookIvar<UIView *>(self, "_artistSongAlbumContainer");
    [view addGestureRecognizer:longPress];   
    [longPress release];
}

%new(v@:@)
- (void)longPress:(UILongPressGestureRecognizer *)gesture 
{
    PostFunction();
}

- (void)layoutArtistSongAlbumLabels
{
    %orig;
    artist = MSHookIvar<UILabel *>(self, "_albumArtistLabel").text;
    song = MSHookIvar<UILabel *>(self, "_songLabel").text;
}
%end

%hook MRNowPlayingFrontScreen
- (void)setArtworkImage:(id)arg1
{
    %orig;
    artwork = arg1;
}
%end

%hook MRNowPlayingScreen_iPad
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

%hook MRiTunesInterface_iPad
- (id)currentMainContentScreen
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
    id formatPadPref = [dict objectForKey:@"FormatPad"];
    formatPad = formatPadPref ? [formatPadPref copy] : @"_SONG_ / _ARTIST_ #NowPlaying";
    id artworkPref = [dict objectForKey:@"isArtworkEnabled"];
    isArtworkEnabled = artworkPref ? [artworkPref boolValue] : YES;
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
