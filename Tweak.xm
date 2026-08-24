#import <UIKit/UIKit.h>

%hook UITabBar

- (void)layoutSubviews {
    %orig;

    // Target Instagram exclusively
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.burbn.instagram"]) {
        
        // Define floating dimensions
        CGFloat sideMargin = 18.0;
        CGFloat bottomMargin = 16.0;
        CGFloat height = 54.0;
        
        CGRect superBounds = self.superview ? self.superview.bounds : self.bounds;
        CGFloat width = superBounds.size.width - (sideMargin * 2);
        CGFloat x = sideMargin;
        CGFloat y = superBounds.size.height - height - bottomMargin;

        // Apply new floating frame
        self.frame = CGRectMake(x, y, width, height);
        
        // Apply pill curvature & clipping
        self.layer.cornerRadius = height / 2.0;
        self.layer.masksToBounds = YES;
        
        // Ensure background blur fits floating frame
        for (UIView *subview in self.subviews) {
            if ([NSStringFromClass([subview class]) containsString:@"Background"]) {
                subview.layer.cornerRadius = height / 2.0;
                subview.clipsToBounds = YES;
            }
        }
    }
}

%end

