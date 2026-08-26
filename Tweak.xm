#import <UIKit/UIKit.h>

static NSString *const kPrefPath = @"/var/jb/var/mobile/Library/Preferences/com.custom.igfloatingtabbar.plist";

// Preferences & Defaults
static BOOL kEnabled = YES;
static CGFloat kSideMargin = 16.0;
static CGFloat kBottomMargin = 16.0;
static CGFloat kBarHeight = 54.0;
static CGFloat kBarAlpha = 0.88;
static CGFloat kRedColor = 0.10;
static CGFloat kGreenColor = 0.10;
static CGFloat kBlueColor = 0.10;
static CGFloat kShadowOpacity = 0.50;
static CGFloat kShadowRadius = 8.0;
static CGFloat kBorderWidth = 0.0;
static CGFloat kBorderAlpha = 0.15;

static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (prefs) {
        kEnabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
        kSideMargin = prefs[@"sideMargin"] ? [prefs[@"sideMargin"] floatValue] : 16.0;
        kBottomMargin = prefs[@"bottomMargin"] ? [prefs[@"bottomMargin"] floatValue] : 16.0;
        kBarHeight = prefs[@"barHeight"] ? [prefs[@"barHeight"] floatValue] : 54.0;
        kBarAlpha = prefs[@"barAlpha"] ? [prefs[@"barAlpha"] floatValue] : 0.88;
        kRedColor = prefs[@"redColor"] ? [prefs[@"redColor"] floatValue] : 0.10;
        kGreenColor = prefs[@"greenColor"] ? [prefs[@"greenColor"] floatValue] : 0.10;
        kBlueColor = prefs[@"blueColor"] ? [prefs[@"blueColor"] floatValue] : 0.10;
        kShadowOpacity = prefs[@"shadowOpacity"] ? [prefs[@"shadowOpacity"] floatValue] : 0.50;
        kShadowRadius = prefs[@"shadowRadius"] ? [prefs[@"shadowRadius"] floatValue] : 8.0;
        kBorderWidth = prefs[@"borderWidth"] ? [prefs[@"borderWidth"] floatValue] : 0.0;
        kBorderAlpha = prefs[@"borderAlpha"] ? [prefs[@"borderAlpha"] floatValue] : 0.15;
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
            self.backgroundColor = [UIColor colorWithRed:kRedColor green:kGreenColor blue:kBlueColor alpha:kBarAlpha];
        }

        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:kBorderAlpha].CGColor;
        self.layer.borderWidth = kBorderWidth;

        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = kShadowOpacity;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = kShadowRadius;

        // Cleanly process subviews without breaking icon rendering
        for (UIView *subview in self.subviews) {
            NSString *subClassName = NSStringFromClass([subview class]);

            // Hide ONLY top separator lines by class name
            if ([subClassName containsString:@"Separator"] || [subClassName containsString:@"Hairline"] || [subClassName containsString:@"ShadowView"]) {
                subview.hidden = YES;
                subview.alpha = 0.0;
            }
            // Transparent inner background views
            else if ([subClassName containsString:@"Background"] || [subClassName containsString:@"VisualEffect"] || [subClassName containsString:@"Backdrop"]) {
                subview.layer.cornerRadius = pillRadius;
                subview.layer.masksToBounds = YES;
                subview.clipsToBounds = YES;
                subview.backgroundColor = [UIColor clearColor];
                subview.layer.borderWidth = 0.0;
            }
            // Ensure button icons remain visible on top
            else {
                subview.hidden = NO;
                if (subview.alpha < 0.1) subview.alpha = 1.0;
                [self bringSubviewToFront:subview];
            }
        }

        [parent bringSubviewToFront:self];
    }
}

%end

// Scroll-to-Hide Handler
%hook UIScrollView

- (void)setContentOffset:(CGPoint)contentOffset {
    %orig;

    if (!kEnabled || !gTabBarView) return;

    if (self.contentSize.height <= self.bounds.size.height) return;
    if (contentOffset.y <= 0 || contentOffset.y >= (self.contentSize.height - self.bounds.size.height)) return;

    CGFloat deltaY = contentOffset.y - gLastOffsetY;
    gLastOffsetY = contentOffset.y;

    if (deltaY > 15.0 && !gIsBarHiddenByScroll) { 
        gIsBarHiddenByScroll = YES;
        [UIView animateWithDuration:0.25 animations:^{
            gTabBarView.alpha = 0.0;
            gTabBarView.transform = CGAffineTransformMakeTranslation(0, 80);
        }];
    } else if (deltaY < -15.0 && gIsBarHiddenByScroll) { 
        gIsBarHiddenByScroll = NO;
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
