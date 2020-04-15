package org.apache.cordova.inappbrowser;

import android.util.Log;
import org.apache.cordova.LOG;
import org.json.JSONException;
import org.json.JSONObject;

public class BrowserEventSender {
    protected static final String LOG_TAG = "InAppBrowser.BrowserEventSender";

    // TODO: KPB - not all these are implemented yet, copied from our previous fork
    private static final String LOAD_START_EVENT = "loadstart";
    private static final String LOAD_STOP_EVENT = "loadstop";
    private static final String LOAD_ERROR_EVENT = "loaderror";
    private static final String EXIT_EVENT = "exit";
    private static final String MESSAGE_EVENT = "message";
    private static final String HIDDEN_EVENT = "hidden";
    private static final String UNHIDDEN_EVENT = "unhidden";
    private static final String BRIDGE_RESPONSE_EVENT = "bridgeresponse";
    private static final String CUSTOM_SCHEME_EVENT = "customscheme";

    private PluginResultSender pluginResultSender;

    public BrowserEventSender(final PluginResultSender resultSender) {
        pluginResultSender = resultSender;
    }

    public void loadStart(String newLocation){
        try {
            JSONObject response = CreateResponse(LOAD_START_EVENT);
            response.put("url", newLocation);
            pluginResultSender.ok(response);
        } catch (JSONException ex) {
            LOG.e(LOG_TAG, "URI passed in has caused a JSON error.");
        }
    }

    public void loadStop(String url){
        try {
            JSONObject response = CreateResponse(LOAD_STOP_EVENT);
            response.put("url", url);
            pluginResultSender.ok(response);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build loadstop response object");
        }
    }

    public void error(String failingUrl, int errorCode, String errorMessage){
        try {
            LOG.e(LOG_TAG, errorMessage);
            JSONObject response = CreateResponse(LOAD_ERROR_EVENT);
            response.put("url", failingUrl);
            response.put("code", errorCode);
            response.put("message", errorMessage);
            pluginResultSender.error(response);
        } catch (JSONException ex) {
            LOG.e(LOG_TAG, "Error sending loaderror for " + failingUrl + ": " + ex.toString());
        }
    }

    public void exit() {
        try {
            JSONObject response = CreateResponse(EXIT_EVENT);
            pluginResultSender.closing(response);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build exit event object");
        }
    }

    // KPB - this is new functionality from the Apache team.
    public void message(String data) {
        try {
            JSONObject obj = CreateResponse(MESSAGE_EVENT);
            obj.put("data", new JSONObject(data));
            pluginResultSender.ok(obj);
        } catch (JSONException ex) {
            LOG.e(LOG_TAG, "data object passed to postMessage has caused a JSON error.");
        }
    }

    // TODO: KPB - the following are ported from our fork ready for use, but not used
    // in the current branch.
    public void hidden(){
        try {
            JSONObject response = CreateResponse(HIDDEN_EVENT);
            pluginResultSender.ok(response);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build Hidden event object");
        }
    }

    public void unhidden() {
        try {
            JSONObject response = CreateResponse(UNHIDDEN_EVENT);
            pluginResultSender.ok(response);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build Unhidden event object");
        }
    }

    public void bridgeResponse(String scriptResult) {
        try {
            JSONObject responseObject = CreateResponse(BRIDGE_RESPONSE_EVENT);
            responseObject.put("data", scriptResult);
            pluginResultSender.ok(responseObject);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build poll result response object");
        }
    }

    public void customScheme(String url) {
        try {
            JSONObject responseObject = CreateResponse(CUSTOM_SCHEME_EVENT);
            responseObject.put("url", url);
            pluginResultSender.ok(responseObject);
        } catch (JSONException ex) {
            Log.d(LOG_TAG, "Failed to build custom scheme result response object");
        }
    }

    private JSONObject CreateResponse(String type) throws JSONException{
        JSONObject response = new JSONObject();
        response.put("type", type);
        return response;
    }
}