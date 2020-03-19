#pragma mark ******************** WIP
#import "WindowState.h"

static bool unhiding = NO;
static bool showing = NO;
static bool hiding = NO;
static bool closing = NO;
static bool openable = YES; // was canOpen

@implementation WindowState

+ (void)availableToOpen {
    openable = YES; // was canOpen
}

+ (void)close {
    unhiding = NO;
    showing = NO;
    hiding = NO;
    closing = NO;
    closing = YES;
}

+ (void)closed {
    unhiding = NO;
    showing = NO;
    hiding = NO;
    closing = NO;
    // openable = YES; // TODO: KPB - confirm, untested but this is likely to be the case.

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