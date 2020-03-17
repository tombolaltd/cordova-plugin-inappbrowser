#import "WindowState.h"

static bool unhiding = NO;
static bool showing = NO;
static bool hiding = NO;
static bool closing = NO;
static bool openable = YES; // was canOpen

@implementation WindowState

+ (void)availableToOpen {
    openable = YES;
}

+ (void)close {
    closing = YES;
}

+ (void)closed {
    unhiding = NO;
    showing = NO;
    hiding = NO;
    closing = NO;
}

+ (void)hide {
    hiding = YES;
}

+ (void)unhide {
    openable = NO;
    unhiding = YES;
}

+ (void)unhidden {
    unhiding = NO;
}

+ (void)opening {
    openable = NO;
}

+ (void)showingDone {
    showing = NO;
}

+ (bool)canHide {
    return showing || unhiding || hiding;
}

+ (bool)canOpen {
    return openable;
}

+ (bool)isUnhiding {
    return unhiding;
}
@end