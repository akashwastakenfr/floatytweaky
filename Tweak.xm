#import <UIKit/UIKit.h>

static NSString *const kPrefPath = @"/var/jb/var/mobile/Library/Preferences/com.custom.igfloatingtabbar.plist";

// Preferences & Defaults
static BOOL kEnabled = YES;
static CGFloat kSideMargin = 16.0;
static CGFloat kBottomMargin = 16.0;
static CGFloat kBarHeight = 54.0;
static CGFloat kBarAlpha = 0.88;
static CGFloat kIconSpacing = 8.0;
static NSString *kHexColor = @"#1A1A1A";

// Helper: Convert Hex String to UIColor
static UIColor *colorFromHexString(NSString *hexString) {
    if (!hexString || hexString.length == 0) return [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:1.0];
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (cleanString.length == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)], [cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)], [cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)], [cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:cleanString];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                           green:((rgbValue & 0xFF00) >> 8) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    if (prefs) {
        kEnabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
        kSideMargin = prefs[@"sideMargin"] ? [prefs[@"sideMargin"] floatValue] : 16.0;
        kBottomMargin = prefs[@"bottomMargin"] ? [prefs[@"bottomMargin"] floatValue] : 16.0;
        kBarHeight = prefs[@"barHeight"] ? [prefs[@"barHeight"] floatValue] : 54.0;
        kBarAlpha = prefs[@"barAlpha"] ? [prefs[@"barAlpha"] floatValue] : 0.88;
        kIconSpacing = prefs[@"iconSpacing"] ? [prefs[@"iconSpacing"] floatValue] : 8.0;
        kHexColor = prefs[@"hexColor"] ? prefs[@"hexColor"] : @"#1A1A1A";
    }
}

static __weak UIView *gTabBarView = nil;
static BOOL gIsBarHiddenByScroll = NO;
static CGFloat gLastOffsetY = 0;

// Extracted animation helper (avoids inline block brace miscounts in Logos)
static void setTabBarVisibilityAnimated(UIView *barView, BOOL visible) {
    if (!barView) return;
    [UIView animateWithDuration:0.25 animations:^{
        barView.alpha = visible ? 1.0 : 0.0;
        barView.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, 80);
    }];
}

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
            UIColor *baseColor = colorFromHexString(kHexColor);
            self.backgroundColor = [baseColor colorWithAlphaComponent:kBarAlpha];
        }

        self.layer.shadowOpacity = 0.0;
        self.layer.borderWidth = 0.0;

        // Remove top border/line CALayers
        if (self.layer.sublayers) {
            for (CALayer *layer in [self.layer.sublayers copy]) {
                if (layer.frame.size.height <= 2.0 || [NSStringFromClass([layer class]) containsString:@"Separator"]) {
                    [layer removeFromSuperlayer];
                }
            }
        }

        NSMutableArray<UIView *> *tabButtons = [NSMutableArray array];

        for (UIView *subview in self.subviews) {
            NSString *subClassName = NSStringFromClass([subview class]);

            // Hide hairline separator views
            if ([subClassName containsString:@"Separator"] || 
                [subClassName containsString:@"Hairline"] || 
                [subClassName containsString:@"Shadow"] || 
                [subClassName containsString:@"Line"] || 
                [subClassName containsString:@"Border"] ||
                subview.frame.size.height <= 3.0) {
                
                subview.hidden = YES;
                subview.alpha = 0.0;
                [subview removeFromSuperview];
            }
            // Strip inner default background views
            else if ([subClassName containsString:@"Background"] || 
                     [subClassName containsString:@"VisualEffect"] || 
                     [subClassName containsString:@"Backdrop"]) {
                subview.layer.cornerRadius = pillRadius;
                subview.layer.masksToBounds = YES;
                subview.clipsToBounds = YES;
                subview.backgroundColor = [UIColor clearColor];
                subview.layer.borderWidth = 0.0;
            }
            // Tab Buttons
            else {
                subview.hidden = NO;
                if (subview.alpha < 0.1) subview.alpha = 1.0;
                [tabButtons addObject:subview];
                [self bringSubviewToFront:subview];
            }
        }

        // Apply Icon Inner Spacing
        if (tabButtons.count > 0) {
            CGFloat usableWidth = targetWidth - (kIconSpacing * 2);
            CGFloat itemWidth = usableWidth / tabButtons.count;

            for (NSInteger i = 0; i < tabButtons.count; i++) {
                UIView *btn = tabButtons[i];
                CGRect btnFrame = btn.frame;
                btnFrame.origin.x = kIconSpacing + (i * itemWidth);
                btnFrame.size.width = itemWidth;
                btnFrame.origin.y = 0;
                btnFrame.size.height = kBarHeight;
                btn.frame = btnFrame;
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
        setTabBarVisibilityAnimated(gTabBarView, NO);
    } else if (deltaY < -15.0 && gIsBarHiddenByScroll) { 
        gIsBarHiddenByScroll = NO;
        setTabBarVisibilityAnimated(gTabBarView, YES);
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
