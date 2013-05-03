#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

__attribute__((visibility("hidden")))
@interface RemoteTweetListController: PSListController
- (id)specifiers;
@end

@implementation RemoteTweetListController

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"RemoteTweet" target:self] retain];
	}
	return _specifiers;
}

- (void)openTwitter:(id)specifier {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/wa_kinchan"]];
	else [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/wa_kinchan/"]];
}

- (void)openBlog:(id)specifier {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://kindadev.com/blog/"]];
}

- (void)openTwitterSorega4:(id)specifier {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/sorega4"]];
	else [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/sorega4/"]];
}

@end
