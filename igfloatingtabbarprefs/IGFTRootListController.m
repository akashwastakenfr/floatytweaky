#import <Preferences/PSListController.h>

@interface IGFTRootListController : PSListController
@end

@implementation IGFTRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)saveAndReload {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.custom.igfloatingtabbar/reload"),
        NULL,
        NULL,
        YES
    );
}

@end

