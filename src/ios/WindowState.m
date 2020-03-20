#pragma mark ******************** WIP
#import "WindowState.h"

@implementation WindowState

typedef NS_ENUM(NSInteger, WindowStates) {
    Initialising, // 0
    Ready,        // 1
    Opening,      // 2
    Displayed,    // 3
    Hiding,       // 4
    Hidden,       // 5
    Unhiding,     // 6
    Closing,      // 7
    Closed        // 8
};

WindowStates currentState;

// This makes the type a singleton.
+ (instancetype)sharedInstance {
    static WindowState* sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WindowState alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if( self = [super init])
    {
        [self setState:Initialising];
    }
    return self;
}

- (void)setState:(WindowStates)newState
{
    WindowStates oldState = currentState;
    currentState = newState;
    NSLog(@"current window state changed from %lu to %lu", (unsigned long)oldState, (unsigned long)newState);
}

// static bool unhiding = NO;
// static bool showing = NO;
// static bool hiding = NO;
// static bool closing = NO;
// static bool openable = YES; // was canOpen

- (void)initialised
{
    [self setState:Ready];
}

//- (void)availableToOpen
//{
//    // openable = YES; // was canOpen
//}

- (void)close
{
    NSLog(@"window state close");
    [self setState:Closing];
    // unhiding = NO;
    // showing = NO;
    // hiding = NO;
    // closing = NO;
    // closing = YES;
}

- (void)closed
{
    NSLog(@"window state Closed");
    [self setState:Closed];
    // unhiding = NO;
    // showing = NO;
    // hiding = NO;
    // closing = NO;
    // openable = YES; // TODO: KPB - confirm, untested but this is likely to be the case.

}

- (void)hide
{
    [self setState:Hiding];
    // hiding = YES;
}

- (void)unhide
{
    [self setState:Unhiding];
    // openable = NO;
    // unhiding = YES;
}

- (void)unhidden
{
    [self setState:Displayed];
    // unhiding = NO;
}

- (void)opening
{
    [self setState:Opening];
    // openable = NO;
}

- (void)showingDone
{
    [self setState:Ready];
    // showing = NO;
}

- (bool)canHide
{
    // return showing || unhiding || hiding;
    return currentState == Displayed || currentState == Unhiding || currentState == Hiding;
}

- (bool)canOpen
{
    // return openable;
    return currentState == Ready;
}

- (bool)isUnhiding
{
   // return unhiding;
   return currentState == Unhiding;
}
@end
