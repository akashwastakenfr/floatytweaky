#import <UIKit/UIKit.h>

static NSString *const kPrefPath = @"/var/jb/var/mobile/Library/Preferences/com.custom.igfloatingtabbar.plist";

static BOOL kEnabled = YES;
static BOOL kHideOnScroll = YES;
static BOOL kInstantChatHide = YES;
static CGFloat kSideMargin = 16.0;
static CGFloat kBottomMargin = 16.0;
static CGFloat kBarHeight = 54.0;
static CGFloat kAlpha = 0.88;

static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (prefs) {
        kEnabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
        kHideOnScroll = prefs[@"hideOnScroll"] ? [prefs[@"hideOnScroll"] boolValue] : YES;
        kInstantChatHide = prefs[@"instantChatHide"] ? [prefs[@"instantChatHide"] boolValue] : YES;
        kSideMargin = prefs[@"sideMargin"] ? [prefs[@"sideMargin"] floatValue] : 16.0;
        kBottomMargin = prefs[@"bottomMargin"] ? [prefs[@"bottomMargin"] floatValue] : 16.0;
        kBarHeight = prefs[@"barHeight"] ? [prefs[@"barHeight"] floatValue] : 54.0;
        kAlpha = prefs[@"barAlpha"] ? [prefs[@"barAlpha"] floatValue] : 0.88;
    }
}

static __weak UIView *gTabBarView = nil;
static BOOL gIsBarHiddenByScroll = NO;
static CGFloat gLastOffsetY = 0;

%hook UIView

- (void)layoutSubviews {
    %orig;

    if (!kEnabled) return;
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.burbn.instagram"]) return;

    NSString *className = NSStringFromClass([self class]);
    if ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"]) {
        gTabBarView = self;

        // Instant exit: If Instagram marked it hidden, stop forcing layouts immediately
        if (self.hidden || self.alpha == 0.0) return;

        UIView *parent = self.superview;
        if (!parent) return;

        CGRect superBounds = parent.bounds;
        if (superBounds.size.height < 100) return;

        CGFloat targetWidth = superBounds.size.width - (kSideMargin * 2);
        CGFloat targetX = kSideMargin;
        CGFloat targetY = superBounds.size.height - kBarHeight - kBottomMargin;
        CGRect targetFrame = CGRectMake(targetX, targetY, targetWidth, kBarHeight);

        if (!CGRectEqualToRect(self.frame, targetFrame)) {
            self.frame = targetFrame;
        }

        CGFloat pillRadius = kBarHeight / 2.0;
        self.layer.cornerRadius = pillRadius;
        self.layer.masksToBounds = NO;
        self.clipsToBounds = NO;

        if (!gIsBarHiddenByScroll) {
            self.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:kAlpha];
        }
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
        self.layer.borderWidth = 1.0;

        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 8.0;

        for (UIView *subview in self.subviews) {
            NSString *subClassName = NSStringFromClass([subview class]);
            if ([subClassName containsString:@"Background"] || [subClassName containsString:@"VisualEffect"]) {
                subview.layer.cornerRadius = pillRadius;
                subview.layer.masksToBounds = YES;
                subview.clipsToBounds = YES;
                subview.backgroundColor = [UIColor clearColor];
            }
        }

        [parent bringSubviewToFront:self];
    }
}

// Instant Chat Hide Fix: Cut transition animation delay to zero
- (void)setHidden:(BOOL)hidden {
    NSString *className = NSStringFromClass([self class]);
    if ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"]) {
        if (kInstantChatHide && hidden) {
            [UIView performWithoutAnimation:^{
                self.alpha = 0.0;
                %orig(YES);
            }];
            return;
        }
    }
    %orig(hidden);
}

- (void)setAlpha:(CGFloat)alpha {
    NSString *className = NSStringFromClass([self class]);
    if ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"]) {
        if (self.hidden && alpha > 0) {
            %orig(0.0);
            return;
        }
    }
    %orig(alpha);
}

%end

// Smooth Scroll-to-Hide Handler
%hook UIScrollView

- (void)setContentOffset:(CGPoint)contentOffset {
    %orig;

    if (!kEnabled || !kHideOnScroll || !gTabBarView) return;

    // Ignore bounces at extreme top or bottom limits
    if (self.contentSize.height <= self.bounds.size.height) return;
    if (contentOffset.y <= 0 || contentOffset.y >= (self.contentSize.height - self.bounds.size.height)) return;

    CGFloat deltaY = contentOffset.y - gLastOffsetY;
    gLastOffsetY = contentOffset.y;

    // State lock with 15pt threshold prevents flicker during scroll deceleration
    if (deltaY > 15.0 && !gIsBarHiddenByScroll) { 
        gIsBarHiddenByScroll = YES;
        [UIView animateWithDuration:0.2 animations:^{
            gTabBarView.alpha = 0.0;
            gTabBarView.transform = CGAffineTransformMakeTranslation(0, 80);
        }];
    } else if (deltaY < -15.0 && gIsBarHiddenByScroll) { 
        gIsBarHiddenByScroll = NO;
        [UIView animateWithDuration:0.2 animations:^{
            gTabBarView.alpha = 1.0;
            gTabBarView.transform = CGAffineTransformIdentity;
        }];
    }
}

%end

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)loadPrefs,
        CFSTR("com.custom.igfloatingtabbar/reload"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
