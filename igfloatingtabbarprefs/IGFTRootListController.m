#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>

extern char **environ;

// Live Preview Header View
@interface IGFTPreviewHeaderView : UIView <PSHeaderFooterView>
@property (nonatomic, strong) UIView *pillPreviewView;
@end

@implementation IGFTPreviewHeaderView

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 120)]) {
        self.backgroundColor = [UIColor clearColor];

        // Container Box
        UIView *bgBox = [[UIView alloc] initWithFrame:CGRectMake(16, 10, 288, 100)];
        bgBox.autoresizesSubviews = YES;
        bgBox.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bgBox.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];
        bgBox.layer.cornerRadius = 14.0;
        bgBox.clipsToBounds = YES;
        [self addSubview:bgBox];

        // Live Floating Pill Preview
        _pillPreviewView = [[UIView alloc] initWithFrame:CGRectMake(24, 30, 240, 44)];
        _pillPreviewView.layer.cornerRadius = 22.0;
        _pillPreviewView.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.88];
        _pillPreviewView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
        _pillPreviewView.layer.borderWidth = 1.0;
        _pillPreviewView.layer.shadowColor = [UIColor blackColor].CGColor;
        _pillPreviewView.layer.shadowOpacity = 0.5;
        _pillPreviewView.layer.shadowOffset = CGSizeMake(0, 4);
        _pillPreviewView.layer.shadowRadius = 6.0;
        [bgBox addSubview:_pillPreviewView];

        // Sample Tab Bar Icons (SF Symbols)
        NSArray *symbolNames = @[@"house.fill", @"magnifyingglass", @"film", @"paperplane", @"person.crop.circle"];
        CGFloat btnWidth = 240.0 / symbolNames.count;
        for (NSInteger i = 0; i < symbolNames.count; i++) {
            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(i * btnWidth + (btnWidth - 20)/2, 12, 20, 20)];
            if (@available(iOS 13.0, *)) {
                iconView.image = [UIImage systemImageNamed:symbolNames[i]];
            }
            iconView.tintColor = [UIColor whiteColor];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            [_pillPreviewView addSubview:iconView];
        }
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 120.0;
}

@end

// Controller Implementation
@interface IGFTRootListController : PSListController
@end

@implementation IGFTRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    pid_t pid;
    const char *args1[] = {"sbreload", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char *const *)args1, environ);
    
    const char *args2[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char *const *)args2, environ);
}

@end
