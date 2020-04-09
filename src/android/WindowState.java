package org.apache.cordova.inappbrowser;

import org.apache.cordova.LOG;

public class WindowState {
    protected static final String LOG_TAG = "InAppBrowser";

    enum State {
        Initialising,
        Ready,
        Opening,
        Displayed,
        Hiding,
        HidingToBlank,
        Hidden,
        Unhiding,
        Closing,
        Exited
    }

    private static boolean reopenOnNextPageFinished = false;

    private static State currentState = State.Initialising;

    private static void setState(State newState) {
        LOG.d(LOG_TAG, String.format("current window state changed from %s to %s", currentState.name(), newState.name()));
        currentState = newState;
    }

    public static void ready() {
        setState(State.Ready);
    }

    public static void close() {
        setState(State.Closing);
    }

    public static void closed() {
        setState(State.Exited);
    }

    public static void hide() {
        setState(State.Hiding);
    }

    public static void hideToBlank() {
        setState(State.HidingToBlank);
    }

    public static void hidden() {
        setState(State.Hidden);
    }

    public static void unhide() {
        setState(State.Unhiding);
    }

    public static void displayed() {
        setState(State.Displayed);
    }

    public static void opening() {
        setState(State.Opening);
    }

    public static void reopenOnNextPageFinished() {
        reopenOnNextPageFinished = true;
    }

    public static void resetReopenOnNextPageFinished() {
        reopenOnNextPageFinished = false;
    }

// TODO: KPB - TBC, this is different to iOS
//    public static boolean canHide() {
//        return currentState == State.Displayed || currentState == State.Unhiding || currentState == State.Hiding;
//    }

    public static boolean canOpen() {
        // TODO: KPB - TBC, this is different to iOS
        return currentState == State.Ready || currentState == State.Hidden;
    }

    public static boolean isHidden() {
       return currentState == State.Hidden;
    }

    // TODO: KPB -this should be callled
    public static boolean isUnhiding() {
       return currentState == State.Unhiding;
    }

    public static boolean isHiding() {
        return currentState == State.Hiding || currentState == State.HidingToBlank;
    }

    public static boolean shouldHideBlank() {
        return currentState == State.HidingToBlank;
    }

    public static boolean shouldReopenOnNextPageFinished() {
        return reopenOnNextPageFinished;
    }
}