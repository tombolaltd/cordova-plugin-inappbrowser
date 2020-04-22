@interface WindowState : NSObject
    + (instancetype)sharedInstance;

    - (id)init;
    - (void)initialised;

    - (void)close;
    - (void)closed;
    - (void)hide;
    - (void)hidden;
    - (void)opening;
    - (void)unhide;
    - (void)displayed;

    - (bool)canHide;
    - (bool)canOpen;
    - (bool)isHidden;
    - (bool)isUnhiding;
@end
