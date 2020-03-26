#pragma mark ******************** WIP
@interface WindowState : NSObject
    + (instancetype)sharedInstance;

    - (id)init;
    - (void)initialised;

    - (void)availableToOpen;
    - (void)close;
    - (void)closed;
    - (void)hide;
    - (void)hidden;
    - (void)opening;
    - (void)unhide;
    - (void)displayed;
    - (void)showingDone;

    - (bool)canHide;
    - (bool)canOpen;
    - (bool)isUnhiding;
@end
