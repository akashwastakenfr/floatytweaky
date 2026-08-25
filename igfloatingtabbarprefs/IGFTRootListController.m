#import <Preferences/PSListController.h>
#import <spawn.h>

extern char **environ;

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
    
    // Fallback to SpringBoard restart
    const char *args2[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char *const *)args2, environ);
}

@end
