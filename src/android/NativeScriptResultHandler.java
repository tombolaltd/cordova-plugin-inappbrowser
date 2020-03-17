package org.apache.cordova.inappbrowser;
// KPB - this was at the top of InAppBrowser.java, have separated here.
//Note to future devs - if you have any c# experience
//This looks weird. Java doesn't have the equivalent
//of delegates, this is the way to do it.
//default is like internal in c#
interface NativeScriptResultHandler {
    public boolean handle(String scriptResult);
}