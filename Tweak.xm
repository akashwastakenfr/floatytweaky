#import <UIKit/UIKit.h>

%hook UIView

- (void)layoutSubviews {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.burbn.instagram"]) return;

    NSString *className = NSStringFromClass([self class]);

    // Target Instagram's custom tab bar and bottom navigation views
    if ([className containsString:@"IGTabBar"] || [className containsString:@"IGBottomNavigation"]) {
        
        // RED TEST: Turn red to verify injection
        self.backgroundColor = [UIColor systemRedColor];

        CGFloat sideMargin = 16.0;
        CGFloat bottomMargin = 16.0;
        CGFloat height = 52.0;

        UIView *parent = self.superview;
        if (!parent) return;

        CGRect superBounds = parent.bounds;
        CGFloat targetWidth = superBounds.size.width - (sideMargin * 2);
        CGFloat targetX = sideMargin;
        CGFloat targetY = superBounds.size.height - height - bottomMargin;

        CGRect targetFrame = CGRectMake(targetX, targetY, targetWidth, height);

        if (!CGRectEqualToRect(self.frame, targetFrame)) {
            self.frame = targetFrame;
            self.layer.cornerRadius = height / 2.0;
            self.layer.masksToBounds = YES;
            self.clipsToBounds = YES;
        }
    }
}

%end
