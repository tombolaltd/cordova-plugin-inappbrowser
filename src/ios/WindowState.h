@interface WindowState : NSObject {}
    + (void)availableToOpen;
    + (void)close;
    + (void)closed;
    + (void)hide;
    + (void)opening;
    + (void)unhide;
    + (void)unhidden;
    + (void)showingDone;

    + (bool)canHide;
    + (bool)canOpen;
    + (bool)isUnhiding;
@end
