#import <UIKit/UIKit.h>

static NSString *const kPrefPath = @"/var/jb/var/mobile/Library/Preferences/com.custom.igfloatingtabbar.plist";

// Preference Defaults
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

%hook UIView

- (void)layoutSubviews {
    %orig;

    if (!kEnabled) return;
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.burbn.instagram"]) return;

    NSString *className = NSStringFromClass([self class]);
    if ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"]) {
        gTabBarView = self;

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

        self.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:kAlpha];
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

// Instant Chat Hide Fix
- (void)setHidden:(BOOL)hidden {
    NSString *className = NSStringFromClass([self class]);
    if (kInstantChatHide && ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"])) {
        [UIView performWithoutAnimation:^{
            %orig(hidden);
        }];
    } else {
        %orig(hidden);
    }
}

%end

// Scroll-to-Hide Handler for Reels, DMs, & Feeds
%hook UIScrollView

- (void)setContentOffset:(CGPoint)contentOffset {
    %orig;

    if (!kEnabled || !kHideOnScroll || !gTabBarView) return;

    UIPanGestureRecognizer *pan = self.panGestureRecognizer;
    CGPoint velocity = [pan velocityInView:self];

    if (velocity.y < -300) { // Scrolling DOWN -> Hide bar
        [UIView animateWithDuration:0.25 animations:^{
            gTabBarView.alpha = 0.0;
            gTabBarView.transform = CGAffineTransformMakeTranslation(0, 80);
        }];
    } else if (velocity.y > 300) { // Scrolling UP -> Show bar
        [UIView animateWithDuration:0.25 animations:^{
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
