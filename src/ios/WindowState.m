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
    Exited        // 8
};

+ (NSString*)windowStateToString:(enum WindowStates) windowState
{
    NSString *result = nil;

    switch(windowState) {
        case Initialising:
            result = @"Initialising";
            break;
        case Ready:
            result = @"Ready";
            break;
        case Opening:
            result = @"Opening";
            break;
        case Displayed:
            result = @"Displayed";
            break;
        case Hiding:
            result = @"Hiding";
            break;
        case Hidden:
            result = @"Hidden";
            break;
        case Unhiding:
            result = @"Unhiding";
            break;
        case Closing:
            result = @"Closing";
            break;
        case Exited:
            result = @"Exited";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected WindowStates."];
    }

    return result;
}

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

    if (currentState != Initialising)
    {
        [self setState:Initialising];
    }

    return self;
}



- (void)setState:(WindowStates)newState
{
    WindowStates oldState = currentState;
    currentState = newState;
    NSLog(@"current window state changed from %@ to %@", [[self class] windowStateToString:oldState], [[self class] windowStateToString:newState]);
}

- (void)initialised
{
    [self setState:Ready];
}

- (void)close
{
    [self setState:Closing];
}

- (void)closed
{
    [self setState:Exited];
}

- (void)hide
{
    [self setState:Hiding];
}

- (void)hidden
{
    [self setState:Hidden];
}

- (void)unhide
{
    [self setState:Unhiding];
}

- (void)displayed
{
    [self setState:Displayed];
}

- (void)opening
{
    [self setState:Opening];
}

- (bool)canHide
{
    return currentState == Displayed || currentState == Unhiding || currentState == Hiding;
}

- (bool)canOpen
{
    return currentState == Ready;
}

- (bool)isHidden
{
   return currentState == Hidden;
}

- (bool)isUnhiding
{
   return currentState == Unhiding;
}
@end
