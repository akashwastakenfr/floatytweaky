#import <UIKit/UIKit.h>

%hook UITabBar

- (void)layoutSubviews {
    %orig;
    self.backgroundColor = [UIColor systemRedColor];
    self.hidden = NO;
}

%end
