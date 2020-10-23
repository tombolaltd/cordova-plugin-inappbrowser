package org.apache.cordova.inappbrowser;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONObject;

public class PluginResultSender {

    private CallbackContext callbackContext;

    public PluginResultSender(final CallbackContext context) {
        callbackContext = context;
    }

    public void closing(JSONObject result) {
        update(result, false, PluginResult.Status.OK);
    }

    public void error(JSONObject result) {
        update(result, true, PluginResult.Status.ERROR);
    }

    public void ok() {
        ok("");
    }

    public void ok(String response) {
        update(response, true, PluginResult.Status.OK);
    }

    public void update(String response, boolean keepCallback, PluginResult.Status status) {
        if (callbackContext != null) {
            PluginResult pluginResult = new PluginResult(status, response);
            pluginResult.setKeepCallback(keepCallback);
            this.callbackContext.sendPluginResult(pluginResult);
        }
    }

    /**
     * Create a new plugin success result and send it back to JavaScript
     *
     * @param response a JSONObject contain event payload information
     */
    public void ok(JSONObject response) {
        update(response, true, PluginResult.Status.OK);
    }

    /**
     * Create a new plugin result and send it back to JavaScript
     *
     * @param response a JSONObject contain event payload information
     * @param status the status code to return to the JavaScript environment
     */
    public void update(JSONObject response, boolean keepCallback, PluginResult.Status status) {
        if (callbackContext != null) {
            PluginResult result = new PluginResult(status, response);
            result.setKeepCallback(keepCallback);
            callbackContext.sendPluginResult(result);
            if (!keepCallback) {
                callbackContext = null;
            }
        }
    }
}