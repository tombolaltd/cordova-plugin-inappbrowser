package org.apache.cordova.inappbrowser;

import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;
import android.util.Log;
import org.apache.cordova.Config;
import org.apache.cordova.PluginManager;
import org.apache.cordova.CordovaWebView;

public final class UrlSecurityValidation {
    protected static final String LOG_TAG = "InAppBrowser.UrlSecurityValidation";
    /**
     * Determines whether the dialog can navigate to the URL
     * This allows us to specifiy the type of navgation
     *
     * @param url
     * @return true if navigable, otherwise false or null
     */
    private static Boolean shouldAllow(final CordovaWebView webView, final String url, final String pluginManagerMethod) {
        Boolean shouldAllowNavigation = null;

        if (url.startsWith("javascript:")) {
            shouldAllowNavigation = true;
        }
        if (shouldAllowNavigation == null) {
            try {
                Method iuw = Config.class.getMethod("isUrlWhiteListed", String.class);
                shouldAllowNavigation = (Boolean)iuw.invoke(null, url);
            }  catch (NoSuchMethodException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            } catch (IllegalAccessException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            } catch (InvocationTargetException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            }
        }
        if (shouldAllowNavigation == null) {
            try {
                Method gpm = webView.getClass().getMethod("getPluginManager");
                PluginManager pm = (PluginManager)gpm.invoke(webView);
                Method san = pm.getClass().getMethod(pluginManagerMethod, String.class);
                shouldAllowNavigation = (Boolean)san.invoke(pm, url);
            } catch (NoSuchMethodException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            } catch (IllegalAccessException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            } catch (InvocationTargetException e) {
                Log.d(LOG_TAG, e.getLocalizedMessage());
            }
        }
        return shouldAllowNavigation;
    }

    private UrlSecurityValidation(){
        //This declaring the class as final, then making the ctor private is as close
        //to static as you can get for a non-nested class in Java.
    }

    public static Boolean shouldAllowRequest(CordovaWebView webView, String url) {
        return shouldAllow(webView, url, "shouldAllowRequest");
    }

    public static Boolean shouldAllowNavigation(CordovaWebView webView, String url) {
        return shouldAllow(webView, url, "shouldAllowRequest");
    }
}