#import <UIKit/UIKit.h>

// Hardcoded Constants - No Settings
static const CGFloat kSideMargin = 16.0;
static const CGFloat kBottomMargin = 16.0;
static const CGFloat kBarHeight = 54.0;
static const CGFloat kBarAlpha = 0.88;
static const CGFloat kRedColor = 0.10;
static const CGFloat kGreenColor = 0.10;
static const CGFloat kBlueColor = 0.10;
static const CGFloat kShadowOpacity = 0.50;
static const CGFloat kShadowRadius = 8.0;
static const CGFloat kBorderWidth = 0.0;
static const CGFloat kBorderAlpha = 0.15;

static __weak UIView *gTabBarView = nil;
static BOOL gIsBarHiddenByScroll = NO;
static CGFloat gLastOffsetY = 0;

%hook UIView

- (void)layoutSubviews {
    %orig;

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

        // Apply Custom Background RGB + Alpha
        if (!gIsBarHiddenByScroll) {
            self.backgroundColor = [UIColor colorWithRed:kRedColor green:kGreenColor blue:kBlueColor alpha:kBarAlpha];
        }

        // Apply Custom Border
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:kBorderAlpha].CGColor;
        self.layer.borderWidth = kBorderWidth;

        // Apply Custom Shadow
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = kShadowOpacity;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = kShadowRadius;

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

%end

// Smooth Scroll-to-Hide Handler
%hook UIScrollView

- (void)setContentOffset:(CGPoint)contentOffset {
    %orig;

    if (!gTabBarView) return;

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
