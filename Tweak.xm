#import <UIKit/UIKit.h>

%hook UITabBar

- (void)layoutSubviews {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.burbn.instagram"]) return;

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

    // Prevent infinite layout loop recursion
    if (!CGRectEqualToRect(self.frame, targetFrame)) {
        self.frame = targetFrame;
        self.layer.cornerRadius = height / 2.0;
        self.layer.masksToBounds = YES;
        self.clipsToBounds = YES;
    }
}

%end
