---
title: Inappbrowser
description: Open an in-app browser window.
---
<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

|AppVeyor|Travis CI|
|:-:|:-:|
|[![Build status](https://ci.appveyor.com/api/projects/status/github/apache/cordova-plugin-inappbrowser?branch=master)](https://ci.appveyor.com/project/ApacheSoftwareFoundation/cordova-plugin-inappbrowser)|[![Build Status](https://travis-ci.org/apache/cordova-plugin-inappbrowser.svg?branch=master)](https://travis-ci.org/apache/cordova-plugin-inappbrowser)|

# cordova-plugin-inappbrowser

You can show helpful articles, videos, and web resources inside of your app. Users can view web pages without leaving your app.

> To get a few ideas, check out the [sample](#sample) at the bottom of this page or go straight to the [reference](#reference) content.

This plugin provides a web browser view that displays when calling `cordova.InAppBrowser.open()`.

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');

### `window.open`

The `cordova.InAppBrowser.open()` function is defined to be a drop-in replacement
for the `window.open()` function.  Existing `window.open()` calls can use the
InAppBrowser window, by replacing window.open:

    window.open = cordova.InAppBrowser.open;

The InAppBrowser window behaves like a standard web browser,
and can't access Cordova APIs. For this reason, the InAppBrowser is recommended
if you need to load third-party (untrusted) content, instead of loading that
into the main Cordova webview. The InAppBrowser is not subject to the
whitelist, nor is opening links in the system browser.

The InAppBrowser provides by default its own GUI controls for the user (back,
forward, done).

For backwards compatibility, this plugin also hooks `window.open`.
However, the plugin-installed hook of `window.open` can have unintended side
effects (especially if this plugin is included only as a dependency of another
plugin).  The hook of `window.open` will be removed in a future major release.
Until the hook is removed from the plugin, apps can manually restore the default
behaviour:

    delete window.open // Reverts the call back to its prototype's default

Although `window.open` is in the global scope, InAppBrowser is not available until after the `deviceready` event.

    document.addEventListener("deviceready", onDeviceReady, false);
    function onDeviceReady() {
        console.log("window.open works well");
    }

Report issues with this plugin on the [Apache Cordova issue tracker](https://issues.apache.org/jira/issues/?jql=project%20%3D%20CB%20AND%20status%20in%20%28Open%2C%20%22In%20Progress%22%2C%20Reopened%29%20AND%20resolution%20%3D%20Unresolved%20AND%20component%20%3D%20%22Plugin%20InAppBrowser%22%20ORDER%20BY%20priority%20DESC%2C%20summary%20ASC%2C%20updatedDate%20DESC)

##Fork Changes 
The intention is to harmonise the changes so they are available in both Android and IOS at least. We have extended the default functionality to support our more complex use case - the documentation seems to imply the IAB is used for opening basic pages/documents, it can now be used as a sub-system with JavaScript based event bridging. We have added the following, for iOS and Android only:
* Browsers opened with `_system` now work separately to other - now fire and forget, this also improved robustness when we tested.
* `hide` and `unhide` functionality - This puts the browser into the background on android and (by default) blanks the page to release resources. We found the stock browser performance relatively poor on start-up, so we can now open an IAB browser at startup and background it, improving UX. In iOS this closes the window and re-opens it with the same settings as the IAB was first opened with - mirroring the Android functionality. The iOS browser was relatively quick to open, so no performace difference is felt. Events are raised for hide and unhide, once hidden and "blanked" any CSS/JS you may have injected is removed, so you might need to re-establish this.
* When a non `_system` window is loaded, this fork injects a JS-wrappered native object called `JSBridgeObject` - this has one method `respond` which takes a string argument which is passed back to the main app via a new `bridgeresponse` channel. _It is intended to add native close and hide functionality to this object to allow native closing from the this object._
* We have added monitoring for a special object - `{InaAppBrowserAction:"Hide"}` if either the injected JS or bridge response returns this, it will perform the hide action natively (`"Close"` is also an option). This bypasses the need for the main app to respond to an event - when the IAB is visible the main app is running in tha background and the OS restricts its performance.

### (ANDROID ONLY)
We use InAppBrowser in a non-standard way. The existing infrastructure had a couple of limitations on Android which we have attempted to redress:
* Browsers opened as _system we blanked, but not destroyed. On some devices this was enough to cause a crash
* The show method would crash if a _system window was opened, then closed, then the `cordova.InAppBrowser.show()` method called
* We want to keep a persistent _self window open. Open creates a new instance, close blanks (and now destroys) it so it cannot be re-used. We have introduced new functions - `cordova.InAppBrowser.hide()` and `cordova.InAppBrowser.unhide()`. These can be used as a direct replacement for `cordova.InAppBrowser.show()` and `cordova.InAppBrowser.close()` where you want to keep the instance alive - saving load time when opening the InAppBrowser, which can be substantial.  `cordova.InAppBrowser.hide()` takes an optional boolean - if set to true the browser is sent to about:blank to prevent uneccessary work on the device. Similarly `cordova.InAppBrowser.unhide()` takes an optional URL to navigate to beforehand.

### (IOS ONLY)
Due to time constraints we have so far been unable to get the IAB window to truly hide - hiding the IAB, or even it's direct parent resulted in a black screen. To keep the behavior consistent with Android the JavaScript side facade is retains these two methods, but opens/closes the window. 

## <a id="reference">Reference
## Installation

    cordova plugin add cordova-plugin-inappbrowser

If you want all page loads in your app to go through the InAppBrowser, you can
simply hook `window.open` during initialization.  For example:

    document.addEventListener("deviceready", onDeviceReady, false);
    function onDeviceReady() {
        window.open = cordova.InAppBrowser.open;
    }

## cordova.InAppBrowser.open

Opens a URL in a new `InAppBrowser` instance, the current browser
instance, or the system browser.

    var ref = cordova.InAppBrowser.open(url, target, options);

- __ref__: Reference to the `InAppBrowser` window when the target is set to `'_blank'`. _(InAppBrowser)_

- __url__: The URL to load _(String)_. Call `encodeURI()` on this if the URL contains Unicode characters.

- __target__: The target in which to load the URL, an optional parameter that defaults to `_self`. _(String)_

    - `_self`: Opens in the Cordova WebView if the URL is in the white list, otherwise it opens in the `InAppBrowser`.
    - `_blank`: Opens in the `InAppBrowser`.
    - `_system`: Opens in the system's web browser.

- __options__: Options for the `InAppBrowser`. Optional, defaulting to: `location=yes`. _(String)_

    The `options` string must not contain any blank space, and each feature's name/value pairs must be separated by a comma. Feature names are case insensitive.

    All platforms support:

    - __location__: Set to `yes` or `no` to turn the `InAppBrowser`'s location bar on or off.

    Android supports these additional options:

    - __hidden__: set to `yes` to create the browser and load the page, but not show it. The loadstop event fires when loading is complete. Omit or set to `no` (default) to have the browser open and load normally.
    - __beforeload__: set to enable the `beforeload` event to modify which pages are actually loaded in the browser. Accepted values are `get` to intercept only GET requests, `post` to intercept on POST requests or `yes` to intercept both GET & POST requests. Note that POST requests are not currently supported and will be ignored (if you set `beforeload=post` it will raise an error).
    - __clearcache__: set to `yes` to have the browser's cookie cache cleared before the new window is opened
    - __clearsessioncache__: set to `yes` to have the session cookie cache cleared before the new window is opened
    - __closebuttoncaption__: set to a string to use as the close button's caption instead of a X. Note that you need to localize this value yourself.
    - __closebuttoncolor__: set to a valid hex color string, for example: `#00ff00`, and it will change the
    close button color from default, regardless of being a text or default X. Only has effect if user has location set to `yes`.
    - __footer__: set to `yes` to show a close button in the footer similar to the iOS __Done__ button. 
    The close button will appear the same as for the header hence use __closebuttoncaption__ and __closebuttoncolor__ to set its properties.
    - __footercolor__: set to a valid hex color string, for example `#00ff00` or `#CC00ff00` (`#aarrggbb`) , and it will change the footer color from default.
    Only has effect if user has __footer__ set to `yes`.
    - __hardwareback__: set to `yes` to use the hardware back button to navigate backwards through the `InAppBrowser`'s history. If there is no previous page, the `InAppBrowser` will close.  The default value is `yes`, so you must set it to `no` if you want the back button to simply close the InAppBrowser.
    - __hidenavigationbuttons__: set to `yes` to hide the navigation buttons on the location toolbar, only has effect if user has location set to `yes`. The default value is `no`.
    - __hideurlbar__: set to `yes` to hide the url bar on the location toolbar, only has effect if user has location set to `yes`. The default value is `no`.
    - __navigationbuttoncolor__: set to a valid hex color string, for example: `#00ff00`, and it will change the color of both navigation buttons from default. Only has effect if user has location set to `yes` and not hidenavigationbuttons set to `yes`.
    - __toolbarcolor__: set to a valid hex color string, for example: `#00ff00`, and it will change the color the toolbar from default. Only has effect if user has location set to `yes`.
    - __lefttoright__: Set to `yes` to swap positions of the navigation buttons and the close button. Specifically, navigation buttons go to the left and close button to the right.
    - __zoom__: set to `yes` to show Android browser's zoom controls, set to `no` to hide them.  Default value is `yes`.
    - __mediaPlaybackRequiresUserAction__: Set to `yes` to prevent HTML5 audio or video from autoplaying (defaults to `no`).
    - __shouldPauseOnSuspend__: Set to `yes` to make InAppBrowser WebView to pause/resume with the app to stop background audio (this may be required to avoid Google Play issues like described in [CB-11013](https://issues.apache.org/jira/browse/CB-11013)).
    - __useWideViewPort__: Sets whether the WebView should enable support for the "viewport" HTML meta tag or should use a wide viewport. When the value of the setting is `no`, the layout width is always set to the width of the WebView control in device-independent (CSS) pixels. When the value is `yes` and the page contains the viewport meta tag, the value of the width specified in the tag is used. If the page does not contain the tag or does not provide a width, then a wide viewport will be used. (defaults to `yes`).

    iOS supports these additional options:

    - __usewkwebview__: set to `yes` to use WKWebView engine for the InappBrowser. Omit or set to `no` (default) to use UIWebView. Note: Using `usewkwebview=yes` requires that a WKWebView engine plugin be installed in the Cordova project (e.g. [cordova-plugin-wkwebview-engine](https://github.com/apache/cordova-plugin-wkwebview-engine) or [cordova-plugin-ionic-webview](https://github.com/ionic-team/cordova-plugin-ionic-webview)).
    - __hidden__: set to `yes` to create the browser and load the page, but not show it. The loadstop event fires when loading is complete. Omit or set to `no` (default) to have the browser open and load normally.
    - __beforeload__: set to enable the `beforeload` event to modify which pages are actually loaded in the browser. Accepted values are `get` to intercept only GET requests, `post` to intercept on POST requests or `yes` to intercept both GET & POST requests. Note that POST requests are not currently supported and will be ignored (if you set `beforeload=post` it will raise an error).
    - __clearcache__: set to `yes` to have the browser's cookie cache cleared before the new window is opened
    - __clearsessioncache__: set to `yes` to have the session cookie cache cleared before the new window is opened. For WKWebView, requires iOS 11+ on target device.
    - __cleardata__: set to `yes` to have the browser's entire local storage cleared (cookies, HTML5 local storage, IndexedDB, etc.) before the new window is opened
    - __closebuttoncolor__: set as a valid hex color string, for example: `#00ff00`, to change from the default __Done__ button's color. Only applicable if toolbar is not disabled.
    - __closebuttoncaption__: set to a string to use as the __Done__ button's caption. Note that you need to localize this value yourself.
    - __disallowoverscroll__: Set to `yes` or `no` (default is `no`). Turns on/off the UIWebViewBounce property.
    - __hidenavigationbuttons__:  set to `yes` or `no` to turn the toolbar navigation buttons on or off (defaults to `no`). Only applicable if toolbar is not disabled.
    - __navigationbuttoncolor__:  set as a valid hex color string, for example: `#00ff00`, to change from the default color. Only applicable if navigation buttons are visible.
    - __toolbar__:  set to `yes` or `no` to turn the toolbar on or off for the InAppBrowser (defaults to `yes`)
    - __toolbarcolor__: set as a valid hex color string, for example: `#00ff00`, to change from the default color of the toolbar. Only applicable if toolbar is not disabled.
    - __toolbartranslucent__:  set to `yes` or `no` to make the toolbar translucent(semi-transparent)  (defaults to `yes`). Only applicable if toolbar is not disabled.
    - __lefttoright__: Set to `yes` to swap positions of the navigation buttons and the close button. Specifically, close button goes to the right and navigation buttons to the left.
    - __enableViewportScale__:  Set to `yes` or `no` to prevent viewport scaling through a meta tag (defaults to `no`). Only applicable to UIWebView (`usewkwebview=no`) and WKWebView (`usewkwebview=yes`) on iOS 10+.
    - __mediaPlaybackRequiresUserAction__: Set to `yes` to prevent HTML5 audio or video from autoplaying (defaults to `no`). Applicable to UIWebView (`usewkwebview=no`) and WKWebView (`usewkwebview=yes`).
    - __allowInlineMediaPlayback__: Set to `yes` or `no` to allow in-line HTML5 media playback, displaying within the browser window rather than a device-specific playback interface. The HTML's `video` element must also include the `webkit-playsinline` attribute (defaults to `no`). Applicable to UIWebView (`usewkwebview=no`) and WKWebView (`usewkwebview=yes`).
    - __keyboardDisplayRequiresUserAction__: Set to `yes` or `no` to open the keyboard when form elements receive focus via JavaScript's `focus()` call (defaults to `yes`). Only applicable to UIWebView (`usewkwebview=no`).
    - __suppressesIncrementalRendering__: Set to `yes` or `no` to wait until all new view content is received before being rendered (defaults to `no`). Only applicable to UIWebView (`usewkwebview=no`).
    - __presentationstyle__:  Set to `pagesheet`, `formsheet` or `fullscreen` to set the [presentation style](http://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewController_Class/Reference/Reference.html#//apple_ref/occ/instp/UIViewController/modalPresentationStyle) (defaults to `fullscreen`).
    - __transitionstyle__: Set to `fliphorizontal`, `crossdissolve` or `coververtical` to set the [transition style](http://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIViewController_Class/Reference/Reference.html#//apple_ref/occ/instp/UIViewController/modalTransitionStyle) (defaults to `coververtical`).
    - __toolbarposition__: Set to `top` or `bottom` (default is `bottom`). Causes the toolbar to be at the top or bottom of the window.
    - __hidespinner__: Set to `yes` or `no` to change the visibility of the loading indicator (defaults to `no`).

    Windows supports these additional options:

    - __hidden__: set to `yes` to create the browser and load the page, but not show it. The loadstop event fires when loading is complete. Omit or set to `no` (default) to have the browser open and load normally.
    - __hardwareback__: works the same way as on Android platform.
    - __fullscreen__: set to `yes` to create the browser control without a border around it. Please note that if __location=no__ is also specified, there will be no control presented to user to close IAB window.


### Supported Platforms

- Android
- Browser
- iOS
- OSX
- Windows

### Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    var ref2 = cordova.InAppBrowser.open(encodeURI('http://ja.m.wikipedia.org/wiki/ハングル'), '_blank', 'location=yes');

### OSX Quirks

At the moment the only supported target in OSX is `_system`.

`_blank` and `_self` targets are not yet implemented and are ignored silently. Pull requests and patches to get these to work are greatly appreciated.

### Browser Quirks

- Plugin is implemented via iframe,

- Navigation history (`back` and `forward` buttons in LocationBar) is not implemented.

## InAppBrowser

The object returned from a call to `cordova.InAppBrowser.open` when the target is set to `'_blank'`.

### Methods

- addEventListener
- removeEventListener
- close
- show
- hide
- executeScript
- insertCSS

## InAppBrowser.addEventListener

> Adds a listener for an event from the `InAppBrowser`. (Only available when the target is set to `'_blank'`)

    ref.addEventListener(eventname, callback);

- __ref__: reference to the `InAppBrowser` window _(InAppBrowser)_

- __eventname__: the event to listen for _(String)_

  - __loadstart__: event fires when the `InAppBrowser` starts to load a URL.
  - __loadstop__: event fires when the `InAppBrowser` finishes loading a URL.
  - __loaderror__: event fires when the `InAppBrowser` encounters an error when loading a URL.
  - __exit__: event fires when the `InAppBrowser` window is closed.
  - __beforeload__: event fires when the `InAppBrowser` decides whether to load an URL or not (only with option `beforeload` set).
  - __message__: event fires when the `InAppBrowser` receives a message posted from the page loaded inside the `InAppBrowser` Webview.

- __callback__: the function that executes when the event fires. The function is passed an `InAppBrowserEvent` object as a parameter.

## Example

```javascript

var inAppBrowserRef;

function showHelp(url) {

    var target = "_blank";

    var options = "location=yes,hidden=yes,beforeload=yes";

    inAppBrowserRef = cordova.InAppBrowser.open(url, target, options);

    inAppBrowserRef.addEventListener('loadstart', loadStartCallBack);

    inAppBrowserRef.addEventListener('loadstop', loadStopCallBack);

    inAppBrowserRef.addEventListener('loaderror', loadErrorCallBack);

    inAppBrowserRef.addEventListener('beforeload', beforeloadCallBack);

    inAppBrowserRef.addEventListener('message', messageCallBack);
}

function loadStartCallBack() {

    $('#status-message').text("loading please wait ...");

}

function loadStopCallBack() {

    if (inAppBrowserRef != undefined) {

        inAppBrowserRef.insertCSS({ code: "body{font-size: 25px;}" });

        inAppBrowserRef.executeScript({ code: "\
            var message = 'this is the message';\
            var messageObj = {my_message: message};\
            var stringifiedMessageObj = JSON.stringify(messageObj);\
            webkit.messageHandlers.cordova_iab.postMessage(stringifiedMessageObj);"
        });

        $('#status-message').text("");

        inAppBrowserRef.show();
    }

}

function loadErrorCallBack(params) {

    $('#status-message').text("");

    var scriptErrorMesssage =
       "alert('Sorry we cannot open that page. Message from the server is : "
       + params.message + "');"

    inAppBrowserRef.executeScript({ code: scriptErrorMesssage }, executeScriptCallBack);

    inAppBrowserRef.close();

    inAppBrowserRef = undefined;

}

function executeScriptCallBack(params) {

    if (params[0] == null) {

        $('#status-message').text(
           "Sorry we couldn't open that page. Message from the server is : '"
           + params.message + "'");
    }

}

function beforeloadCallBack(params, callback) {

    if (params.url.startsWith("http://www.example.com/")) {

        // Load this URL in the inAppBrowser.
        callback(params.url);
    } else {

        // The callback is not invoked, so the page will not be loaded.
        $('#status-message').text("This browser only opens pages on http://www.example.com/");
    }

}

function messageCallBack(params){
    $('#status-message').text("message received: "+params.data.my_message);
}

```

### InAppBrowserEvent Properties

- __type__: the eventname, either `loadstart`, `loadstop`, `loaderror`, `message` or `exit`. _(String)_

- __url__: the URL that was loaded. _(String)_

- __code__: the error code, only in the case of `loaderror`. _(Number)_

- __message__: the error message, only in the case of `loaderror`. _(String)_

- __data__: the message contents , only in the case of `message`. A stringified JSON object. _(String)_


### Supported Platforms

- Android
- Browser
- iOS
- Windows
- OSX

`loadstop` is being fired after a `customscheme` event. The event URL is that of the currently loaded page, not the URL with the custom scheme.

### Browser Quirks

`loadstart`, `loaderror`, `message` events are not fired.

### Windows Quirks

`message` event is not fired.

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.addEventListener('loadstart', function(event) { alert(event.url); });

## InAppBrowser.removeEventListener

> Removes a listener for an event from the `InAppBrowser`. (Only available when the target is set to `'_blank'`)

    ref.removeEventListener(eventname, callback);

- __ref__: reference to the `InAppBrowser` window. _(InAppBrowser)_

- __eventname__: the event to stop listening for. _(String)_

  - __loadstart__: event fires when the `InAppBrowser` starts to load a URL.
  - __loadstop__: event fires when the `InAppBrowser` finishes loading a URL.
  - __loaderror__: event fires when the `InAppBrowser` encounters an error loading a URL.
  - __exit__: event fires when the `InAppBrowser` window is closed.
  - __message__: event fires when the `InAppBrowser` receives a message posted from the page loaded inside the `InAppBrowser` Webview.
  - __customscheme__: event fires when a link is followed that matches `AllowedSchemes` (Android, iOS).

- __callback__: the function to execute when the event fires.
The function is passed an `InAppBrowserEvent` object.

### Supported Platforms

- Android
- Browser
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    var myCallback = function(event) { alert(event.url); }
    ref.addEventListener('loadstart', myCallback);
    ref.removeEventListener('loadstart', myCallback);

## InAppBrowser.close

> Closes the `InAppBrowser` window.

    ref.close();

- __ref__: reference to the `InAppBrowser` window _(InAppBrowser)_

### Supported Platforms

- Android
- Browser
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.close();

## InAppBrowser.show

> Displays an InAppBrowser window that was opened hidden. Calling this has no effect if the InAppBrowser was already visible.

    ref.show();

- __ref__: reference to the InAppBrowser window (`InAppBrowser`)

### Supported Platforms

- Android
- Browser
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'hidden=yes');
    // some time later...
    ref.show();

## InAppBrowser.hide

> Hides the InAppBrowser window. Calling this has no effect if the InAppBrowser was already hidden.

    ref.hide();

- __ref__: reference to the InAppBrowser window (`InAppBrowser`)

### Supported Platforms

- Android
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank');
    // some time later...
    ref.hide();

## InAppBrowser.executeScript

> Injects JavaScript code into the `InAppBrowser` window. (Only available when the target is set to `'_blank'`)

    ref.executeScript(details, callback);

- __ref__: reference to the `InAppBrowser` window. _(InAppBrowser)_

- __injectDetails__: details of the script to run, specifying either a `file` or `code` key. _(Object)_
  - __file__: URL of the script to inject.
  - __code__: Text of the script to inject.

- __callback__: the function that executes after the JavaScript code is injected.
    - If the injected script is of type `code`, the callback executes
      with a single parameter, which is the return value of the
      script, wrapped in an `Array`. For multi-line scripts, this is
      the return value of the last statement, or the last expression
      evaluated.

### Supported Platforms

- Android
- Browser
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.addEventListener('loadstop', function() {
        ref.executeScript({file: "myscript.js"});
    });

### Browser Quirks

- only __code__ key is supported.

### Windows Quirks

Due to [MSDN docs](https://msdn.microsoft.com/en-us/library/windows.ui.xaml.controls.webview.invokescriptasync.aspx) the invoked script can return only string values, otherwise the parameter, passed to __callback__ will be `[null]`.

## InAppBrowser.insertCSS

> Injects CSS into the `InAppBrowser` window. (Only available when the target is set to `'_blank'`)

    ref.insertCSS(details, callback);

- __ref__: reference to the `InAppBrowser` window _(InAppBrowser)_

- __injectDetails__: details of the script to run, specifying either a `file` or `code` key. _(Object)_
  - __file__: URL of the stylesheet to inject.
  - __code__: Text of the stylesheet to inject.

- __callback__: the function that executes after the CSS is injected.

### Supported Platforms

- Android
- iOS
- Windows

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.addEventListener('loadstop', function() {
        ref.insertCSS({file: "mystyles.css"});
    });
__

## InAppBrowser.show

> Shows the `InAppBrowser` if opened with the hidden option true.

    ref.hide(newUrl);

- __ref__: reference to the `InAppBrowser` window _(InAppBrowser)_ . Must be hidden to take effect.

- __newUrl__: Optional, The new URL to navigate to before showing(waits for page load to finish). _(String)_
 

### Supported Platforms

- Android

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_system', 'location=yes, hidden=yes');
    //Should really wait until the page loadstop event
    ref.show("http://www.google.com");
__

## InAppBrowser.hide

> Hides the `InAppBrowser` for non _system windows.

    ref.hide(blankUrl);

- __ref__: reference to the `InAppBrowser` window _(InAppBrowser)_ . Must have target '_blank' or '_self' to take effect.

- __blankUrl__: Optional, If, true if the browser navigates to about:blank to preserve resources before hide. _(Boolean)_
 

### Supported Platforms

- Does not operate with the `_system` option.
- Android
- iOS (see IOS ONLY section above - `blankUrl` has no effect, same as `true` under Android). 

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.hide();
__

## InAppBrowser.unhide

> unhides the `InAppBrowser` for non _system windows. The widow should previously have been hidden, though `uhide` also should work with IAB instances that have started with `hidden=true`.

    ref.unhide(newUrl);

- __newUrl__: The url to navigate to before unhiding, if using iOS, or the `hide` method was called `blankUrl` unset or set to `true` you should supply this, otherwise you will get a blank page. The page is unhidden on the new URL's loadstop event, if for any reason this is not triggered the IAB will not display.
 

### Supported Platforms

- Does not operate with the `_system` option.
- Android
- iOS (see IOS ONLY section above, really a new instance is opened with the same settings as it was opened with).

### Quick Example

    var ref = cordova.InAppBrowser.open('http://apache.org', '_blank', 'location=yes');
    ref.hide();
    //Should really do this on the 'hidden' event
    ref.unhide('');
__

## <a id="bridging"></a>Sample: How to bridge your InAppBrowser with the client
A few points, first our use case is for android and iOS only - changes have only been made with these operating systems. We have provided:
* The ability to interact with native code from the IAB javascript in a limited way (only `close` and `hide`) from the IAB JavaScript context / 'executeScript'. You can inject JavaScript from the app which returns a specific object to do this: `{InAppBrowserAction: "hide"}` where the action can be either `hide` or `close`. When processed the relevant event(s) will be raised. This provides an extensibility point for future forks, and bypasses the need for the app iteslf to respond initially - the task is backgrounded will be running slowly. If the object does not follow the structure specified it will be just returned to the main app - it is worth checking the system logs if this happens unexpectedly for mor information.
* An object `JSBridgeObject` which has a `respond` method. If the object passed (represented as a JSON string) into this method is one of the native action ones, it is handled the same way as above. Otherwise the string is passed back through a new `bridgeresponse` event.

### <a id="executeScriptBridge"></a>Using Execute Script to Bridge
Assuming your loaded page has an object `bridge` with a value `eventName`:
```javascript
var innerScript = [ 
     'if (bridge && bridge.eventname) {',
    	    'if (bridge.eventName === \'hide\') {',
	        'return { InAppBrowserAction:"hide" };',
	     '}',
	    'return {myEventName: bridge.eventname};',
        '}'
    ].join(''),
  
    pollScript = 'setInterval(function(){ return JSON.stringify(' + innerScript + '); },500);', 
    ref = cordova.InAppBrowser.open('http://mypage.org', '_blank', 'location=yes');
    
function appEventHandler (data){
    alert(JSON.parse(data).myEventName);
}
    ref.executeScript(pollScript, appEventHandler);
```
This method caused problems with older versions of iOS (it updates the url, refeshing the page and causing other events to fire. This also disrupted the polling, which no longer fired.). It also is less readily extensible, we suggest the next method of establishing a brdge.

### <a id="executeScriptBridge"></a>Using the new Bridge infrastructure
```javascript
//innerScript is the same as the previous sample
var innerScript = [ 
     'if (bridge && bridge.eventname) {',
    	    'if (bridge.eventName === \'hide\') {',
	        'return { InAppBrowserAction:"hide" };',
	     '}',
	    'return {myEventName: bridge.eventname};',
        '}'
    ].join(''),
    //pollScript only differs in calling the bridge respond method rather than returning
    pollScript = 'setInterval(function(){ JavaScriptBridgeInterfaceObject.respond((JSON.stringify(' + innerScript + ')); },500);', 
    ref = cordova.InAppBrowser.open('http://mypage.org', '_blank', 'location=yes');

//Again, this is the same handler as the previous example, it is just isn't passed as a callback on execute anymore.
function appEventHandler (data){
    alert(JSON.parse(data).myEventName);
}

ref.addEventListener('bridgeresponse', appEventHandler);
ref.executeScript(pollScript);
```

Not that in both cases the polling script will stop if the page is navigated, if you need this to continue you can re-inject the script. The event handler does not need to be re-registered.

## <a id="sample"></a>Sample: Show help pages with an InAppBrowser

You can use this plugin to show helpful documentation pages within your app. Users can view online help documents and then close them without leaving the app.

Here's a few snippets that show how you do this.

* [Give users a way to ask for help](#give).
* [Load a help page](#load).
* [Let users know that you're getting their page ready](#let).
* [Show the help page](#show).
* [Handle page errors](#handle).

### <a id="give"></a>Give users a way to ask for help

There's lots of ways to do this in your app. A drop down list is a simple way to do that.

```html

<select id="help-select">
    <option value="default">Need help?</option>
    <option value="article">Show me a helpful article</option>
    <option value="video">Show me a helpful video</option>
    <option value="search">Search for other topics</option>
</select>

```

Gather the users choice in the ``onDeviceReady`` function of the page and then send an appropriate URL to a helper function in some shared library file. Our helper function is named ``showHelp()`` and we'll write that function next.

```javascript

$('#help-select').on('change', function (e) {

    var url;

    switch (this.value) {

        case "article":
            url = "https://cordova.apache.org/docs/en/latest/"
                        + "reference/cordova-plugin-inappbrowser/index.html";
            break;

        case "video":
            url = "https://youtu.be/F-GlVrTaeH0";
            break;

        case "search":
            url = "https://www.google.com/#q=inAppBrowser+plugin";
            break;
    }

    showHelp(url);

});

```

### <a id="load"></a>Load a help page

We'll use the ``open`` function to load the help page. We're setting the ``hidden`` property to ``yes`` so that we can show the browser only after the page content has loaded. That way, users don't see a blank browser while they wait for content to appear. When the ``loadstop`` event is raised, we'll know when the content has loaded. We'll handle that event shortly.

```javascript

function showHelp(url) {

    var target = "_blank";

    var options = "location=yes,hidden=yes";

    inAppBrowserRef = cordova.InAppBrowser.open(url, target, options);

    inAppBrowserRef.addEventListener('loadstart', loadStartCallBack);

    inAppBrowserRef.addEventListener('loadstop', loadStopCallBack);

    inAppBrowserRef.addEventListener('loaderror', loadErrorCallBack);

}

```

### <a id="let"></a>Let users know that you're getting their page ready

Because the browser doesn't immediately appear, we can use the ``loadstart`` event to show a status message, progress bar, or other indicator. This assures users that content is on the way.

```javascript

function loadStartCallBack() {

    $('#status-message').text("loading please wait ...");

}

```

### <a id="show"></a>Show the help page

When the ``loadstopcallback`` event is raised, we know that the content has loaded and we can make the browser visible. This sort of trick can create the impression of better performance. The truth is that whether you show the browser before content loads or not, the load times are exactly the same.

```javascript

function loadStopCallBack() {

    if (inAppBrowserRef != undefined) {

        inAppBrowserRef.insertCSS({ code: "body{font-size: 25px;}" });

        $('#status-message').text("");

        inAppBrowserRef.show();
    }

}

```
You might have noticed the call to the ``insertCSS`` function. This serves no particular purpose in our scenario. But it gives you an idea of why you might use it. In this case, we're just making sure that the font size of your pages have a certain size. You can use this function to insert any CSS style elements. You can even point to a CSS file in your project.

### <a id="handle"></a>Handle page errors

Sometimes a page no longer exists, a script error occurs, or a user lacks permission to view the resource. How or if you handle that situation is completely up to you and your design. You can let the browser show that message or you can present it in another way.

We'll try to show that error in a message box. We can do that by injecting a script that calls the ``alert`` function. That said, this won't work in browsers on Windows devices so we'll have to look at the parameter of the ``executeScript`` callback function to see if our attempt worked. If it didn't work out for us, we'll just show the error message in a ``<div>`` on the page.

```javascript

function loadErrorCallBack(params) {

    $('#status-message').text("");

    var scriptErrorMesssage =
       "alert('Sorry we cannot open that page. Message from the server is : "
       + params.message + "');"

    inAppBrowserRef.executeScript({ code: scriptErrorMesssage }, executeScriptCallBack);

    inAppBrowserRef.close();

    inAppBrowserRef = undefined;

}

function executeScriptCallBack(params) {

    if (params[0] == null) {

        $('#status-message').text(
           "Sorry we couldn't open that page. Message from the server is : '"
           + params.message + "'");
    }

}

```

### <a id="events_from_browser"></a>Events from the browser

Sometimes you may want to respond to an event happening on the page loaded in the browser,
for example a button to open the barcode scanner, or closing the browser when a login flow
was finished. This can done by navigating to a URL with a custom scheme listed in the
`AllowedSchemes` preference in `config.xml`, triggering a `customscheme` event on the
browser. Multiple values are separated by comma's.

In `config.xml`, include the following:
```xml
<preference name="AllowedSchemes" value="app" />
```

```javascript
function onCustomScheme(e) {
  if (e.url === 'app://hide') {
    inAppBrowserRef.hide();
  }
}
inAppBrowserRef = cordova.InAppBrowser.open('https://example.com', '_blank');
inAppBrowserRef.addEventListener('customscheme', onCustomScheme);
```

When the opened page navigates to the link `app://hide`, the browser is hidden.

Please note that this feature is only available on Android and iOS (pull requests
for other platforms are welcome).

## More Usage Info

### Local Urls ( source is in the app package )
```
var iab = cordova.InAppBrowser;

iab.open('local-url.html');                  // loads in the Cordova WebView
iab.open('local-url.html', '_self');         // loads in the Cordova WebView
iab.open('local-url.html', '_system');       // Security error: system browser, but url will not load (iOS)
iab.open('local-url.html', '_blank');        // loads in the InAppBrowser
iab.open('local-url.html', 'random_string'); // loads in the InAppBrowser
iab.open('local-url.html', 'random_string', 'location=no'); // loads in the InAppBrowser, no location bar

```



### Whitelisted Content

```
var iab = cordova.InAppBrowser;

iab.open('http://whitelisted-url.com');                  // loads in the Cordova WebView
iab.open('http://whitelisted-url.com', '_self');         // loads in the Cordova WebView
iab.open('http://whitelisted-url.com', '_system');       // loads in the system browser
iab.open('http://whitelisted-url.com', '_blank');        // loads in the InAppBrowser
iab.open('http://whitelisted-url.com', 'random_string'); // loads in the InAppBrowser

iab.open('http://whitelisted-url.com', 'random_string', 'location=no'); // loads in the InAppBrowser, no location bar

```

### Urls that are not white-listed

```
var iab = cordova.InAppBrowser;

iab.open('http://url-that-fails-whitelist.com');                  // loads in the InAppBrowser
iab.open('http://url-that-fails-whitelist.com', '_self');         // loads in the InAppBrowser
iab.open('http://url-that-fails-whitelist.com', '_system');       // loads in the system browser
iab.open('http://url-that-fails-whitelist.com', '_blank');        // loads in the InAppBrowser
iab.open('http://url-that-fails-whitelist.com', 'random_string'); // loads in the InAppBrowser
iab.open('http://url-that-fails-whitelist.com', 'random_string', 'location=no'); // loads in the InAppBrowser, no location bar

```
