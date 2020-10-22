/*
       Licensed to the Apache Software Foundation (ASF) under one
       or more contributor license agreements.  See the NOTICE file
       distributed with this work for additional information
       regarding copyright ownership.  The ASF licenses this file
       to you under the Apache License, Version 2.0 (the
       "License"); you may not use this file except in compliance
       with the License.  You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing,
       software distributed under the License is distributed on an
       "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
       KIND, either express or implied.  See the License for the
       specific language governing permissions and limitations
       under the License.
*/
package org.apache.cordova.inappbrowser;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.provider.Browser;
import android.net.Uri;
import android.os.Parcelable;
import android.util.Log;

import org.apache.cordova.CallbackContext;

import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;

@SuppressLint("SetJavaScriptEnabled")
public class SystemBrowser extends CordovaPlugin {
    protected static final String LOG_TAG = "InAppBrowser";

    /**
     * Display a new browser with the specified URL.
     *
     * @param url the url to load.
     * @return "" if ok, or error message.
     */
    private String openExternal(String url) {
        try {
            Intent intent = null;
            intent = new Intent(Intent.ACTION_VIEW);
            // Omitting the MIME type for file: URLs causes "No Activity found to handle Intent".
            // Adding the MIME type to http: URLs causes them to not be handled by the downloader.
            Uri uri = Uri.parse(url);
            if ("file".equals(uri.getScheme())) {
                intent.setDataAndType(uri, webView.getResourceApi().getMimeType(uri));
            } else {
                intent.setData(uri);
            }
            intent.putExtra(Browser.EXTRA_APPLICATION_ID, cordova.getActivity().getPackageName());
            // CB-10795: Avoid circular loops by preventing it from opening in the current app
            // this.openExternalExcludeCurrentApp(intent);
            this.cordova.getActivity().startActivity(intent);
            return "";
        } catch (android.content.ActivityNotFoundException e) {
            Log.d(LOG_TAG, "InAppBrowser: Error loading url "+url+":"+ e.toString());
            return e.toString();
        }
    }

    /**
     * Opens the intent, providing a chooser that excludes the current app to avoid
     * circular loops.
     */
    // private void openExternalExcludeCurrentApp(Intent intent) {
    //     String currentPackage = cordova.getActivity().getPackageName();
    //     boolean hasCurrentPackage = false;

    //     PackageManager pm = cordova.getActivity().getPackageManager();
    //     List<ResolveInfo> activities = pm.queryIntentActivities(intent, 0);
    //     ArrayList<Intent> targetIntents = new ArrayList<Intent>();

    //     for (ResolveInfo ri : activities) {
    //         if (!currentPackage.equals(ri.activityInfo.packageName)) {
    //             Intent targetIntent = (Intent)intent.clone();
    //             targetIntent.setPackage(ri.activityInfo.packageName);
    //             targetIntents.add(targetIntent);
    //         }
    //         else {
    //             hasCurrentPackage = true;
    //         }
    //     }

    //     // If the current app package isn't a target for this URL, then use
    //     // the normal launch behavior
    //     if (hasCurrentPackage == false || targetIntents.size() == 0) {
    //         this.cordova.getActivity().startActivity(intent);
    //     }
    //     // If there's only one possible intent, launch it directly
    //     else if (targetIntents.size() == 1) {
    //         this.cordova.getActivity().startActivity(targetIntents.get(0));
    //     }
    //     // Otherwise, show a custom chooser without the current app listed
    //     else if (targetIntents.size() > 0) {
    //         Intent chooser = Intent.createChooser(targetIntents.remove(targetIntents.size()-1), null);
    //         chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, targetIntents.toArray(new Parcelable[] {}));
    //         this.cordova.getActivity().startActivity(chooser);
    // }
    //     }




    public boolean execute(String action, CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        if(!action.equals("open")){
            return false;
        }

        final String url = args.getString(0);

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(LOG_TAG, "Opening System Browser");
                String result = openExternal(url);

                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, result);
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            }
        });
        return true;
    }
}