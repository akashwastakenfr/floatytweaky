#import <UIKit/UIKit.h>

%hook UIView

- (void)layoutSubviews {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.burbn.instagram"]) return;

    NSString *className = NSStringFromClass([self class]);

    if ([className isEqualToString:@"IGTabBar"] || [className isEqualToString:@"IGTabBarView"]) {
        
        CGFloat sideMargin = 16.0;
        CGFloat bottomMargin = 16.0;
        CGFloat height = 54.0;
        CGFloat pillRadius = height / 2.0; // 27.0pt smooth pill curvature

        UIView *parent = self.superview;
        if (!parent) return;

        CGRect superBounds = parent.bounds;
        if (superBounds.size.height < 100) return;

        CGFloat targetWidth = superBounds.size.width - (sideMargin * 2);
        CGFloat targetX = sideMargin;
        CGFloat targetY = superBounds.size.height - height - bottomMargin;

        CGRect targetFrame = CGRectMake(targetX, targetY, targetWidth, height);

        if (!CGRectEqualToRect(self.frame, targetFrame)) {
            self.frame = targetFrame;
        }

        // Round main container into a pill
        self.layer.cornerRadius = pillRadius;
        self.layer.masksToBounds = NO;
        self.clipsToBounds = NO;

        // Dark Mode translucent background color
        self.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.88];

        // Subtle 1px white outline border for visibility on black feeds
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
        self.layer.borderWidth = 1.0;

        // Deep drop shadow for depth
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 10.0;

        // Apply corner rounding to internal background subviews
        for (UIView *subview in self.subviews) {
            NSString *subClassName = NSStringFromClass([subview class]);
            if ([subClassName containsString:@"Background"] || [subClassName containsString:@"VisualEffect"] || [subClassName containsString:@"Backdrop"]) {
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
