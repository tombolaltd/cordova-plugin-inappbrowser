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

#import "CDVWKInAppBrowser.h"
#import "WindowState.h"
#import "JavaScriptBridgeInterface.h"
#import "ScriptCallBackIdValidator.h"

#if __has_include("CDVWKProcessPoolFactory.h")
#import "CDVWKProcessPoolFactory.h"
#endif

#import <Cordova/CDVUserAgentUtil.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    IAB_BRIDGE_NAME @"cordova_iab"
#define    JAVASCRIPT_BRIDGE_NAME @"tombola_javascript_bridge"

#define    TOOLBAR_HEIGHT 44.0
#define    STATUSBAR_HEIGHT 20.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVWKInAppBrowser

@interface CDVWKInAppBrowser () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVWKInAppBrowser

const WindowState* windowState = nil;

static CDVWKInAppBrowser* instance = nil;

+ (id) getInstance{
    return instance;
}

- (void)setCommandDelegate:(id <CDVCommandDelegate>)theCommandDelegate
{
    [super setCommandDelegate:theCommandDelegate];
    self.cordovaPluginResultProxy = [[CordovaPluginResultProxy alloc] initWithCommanDelegate:theCommandDelegate];
}

- (void)pluginInitialize
{
    instance = self;
    windowState = [WindowState sharedInstance];
    _previousStatusBarStyle = -1;
    _beforeload = @"";
    _waitForBeforeload = NO;
    [windowState initialised];
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

- (void)onReset
{
    [self close:nil];
}

- (void)close:(CDVInvokedUrlCommand*)command
{

    if (self.inAppBrowserViewController == nil) {
        NSLog(@"IAB.close() called but it was already closed.");
        return;
    }

    [windowState close];
    // Things are cleaned up in browserExit.
    [self.inAppBrowserViewController close];
}

// KPB - Checked
- (BOOL) isSystemUrl:(NSURL*)url
{
    if ([[url host] isEqualToString:@"itunes.apple.com"]) {
        return YES;
    }

    return NO;
}

- (void)open:(CDVInvokedUrlCommand*)command
{
	if(![windowState canOpen]){
		return;
	}
	[windowState opening];
    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    self.cordovaPluginResultProxy.callbackId = command.callbackId;
    [self openUrl:url targets:target withOptions:options];
}

- (void)openUrl:(NSString*)url targets:(NSString*)target withOptions:(NSString*)options {
    //NOTE this no longer handles system directly - done in a different plugin in this package

    if (url == nil) {
        [self.cordovaPluginResultProxy sendErrorWithMessageAsString:@"incorrect number of arguments"];
        return;
    }
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];

        if ([self isSystemUrl:absoluteUrl])
        {
            [self openInSystem:absoluteUrl]; // Newer
        }
        else if ([target isEqualToString:kInAppBrowserTargetSelf])
        {
            [self openInCordovaWebView:absoluteUrl withOptions:options];
        }
        else
        {
            // _blank or anything else
            [self openInInAppBrowser:absoluteUrl withOptions:options];
        }

    [self.cordovaPluginResultProxy sendOK];
}

- (void)openInInAppBrowser:(NSURL*)url withOptions:(NSString*)options
{
    CDVInAppBrowserOptions* browserOptions = [CDVInAppBrowserOptions parseOptions:options];

    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
    if (browserOptions.cleardata) {

        NSDate* dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [dataStore removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:dateFrom completionHandler:^{
            NSLog(@"Removed all WKWebView data");
            self.inAppBrowserViewController.webView.configuration.processPool = [[WKProcessPool alloc] init]; // create new process pool to flush all data
        }];
    }

    if (browserOptions.clearcache) {
        if (@available(iOS 11.0, *)) {
            #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
                        // Deletes all cookies
                        WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
                        [cookieStore getAllCookies:^(NSArray* cookies) {
                            NSHTTPCookie* cookie;
                            for(cookie in cookies){
                                [cookieStore deleteCookie:cookie completionHandler:nil];
                            }
                        }];
            #endif
        } else {
            // https://stackoverflow.com/a/31803708/777265
            // Only deletes domain cookies (not session cookies)
            [dataStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes]
             completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
                 for (WKWebsiteDataRecord *record  in records){
                     NSSet<NSString*>* dataTypes = record.dataTypes;
                     if([dataTypes containsObject:WKWebsiteDataTypeCookies]){
                         [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes
                               forDataRecords:@[record]
                               completionHandler:^{}];
                     }
                 }
             }];
        }
    }

    if (browserOptions.clearsessioncache) {
        if (@available(iOS 11.0, *)) {
            #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
            // Deletes session cookies
            WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
            [cookieStore getAllCookies:^(NSArray* cookies) {
                NSHTTPCookie* cookie;
                for(cookie in cookies){
                    if(cookie.sessionOnly){
                        [cookieStore deleteCookie:cookie completionHandler:nil];
                    }
                }
            }];
            #endif
        } else {
            NSLog(@"clearsessioncache not available below iOS 11.0");
        }
    }

    if (self.inAppBrowserViewController == nil) {
        NSString* userAgent = [CDVUserAgentUtil originalUserAgent];
        NSString* overrideUserAgent = [self settingForKey:@"OverrideUserAgent"];
        NSString* appendUserAgent = [self settingForKey:@"AppendUserAgent"];
        if(overrideUserAgent){
            userAgent = overrideUserAgent;
        }
        if(appendUserAgent){
            userAgent = [userAgent stringByAppendingString: appendUserAgent];
        }
        self.inAppBrowserViewController = [[CDVWKInAppBrowserViewController alloc] initWithUserAgent:userAgent prevUserAgent:[self.commandDelegate userAgent] browserOptions: browserOptions];
        self.inAppBrowserViewController.navigationDelegate = self;

        if ([self.viewController conformsToProtocol:@protocol(CDVScreenOrientationDelegate)]) {
            self.inAppBrowserViewController.orientationDelegate = (UIViewController <CDVScreenOrientationDelegate>*)self.viewController;
        }
    }

    [self.inAppBrowserViewController showLocationBar:browserOptions.location];
    [self.inAppBrowserViewController showToolBar:browserOptions.toolbar :browserOptions.toolbarposition];
    if (browserOptions.closebuttoncaption != nil || browserOptions.closebuttoncolor != nil) {
        int closeButtonIndex = browserOptions.lefttoright ? (browserOptions.hidenavigationbuttons ? 1 : 4) : 0;
        [self.inAppBrowserViewController setCloseButtonTitle:browserOptions.closebuttoncaption :browserOptions.closebuttoncolor :closeButtonIndex];
    }
    // Set Presentation Style
    UIModalPresentationStyle presentationStyle = UIModalPresentationFullScreen; // default
    if (browserOptions.presentationstyle != nil) {
        if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"pagesheet"]) {
            presentationStyle = UIModalPresentationPageSheet;
        } else if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"formsheet"]) {
            presentationStyle = UIModalPresentationFormSheet;
        }
    }
    self.inAppBrowserViewController.modalPresentationStyle = presentationStyle;

    // Set Transition Style
    UIModalTransitionStyle transitionStyle = UIModalTransitionStyleCoverVertical; // default
    if (browserOptions.transitionstyle != nil) {
        if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"fliphorizontal"]) {
            transitionStyle = UIModalTransitionStyleFlipHorizontal;
        } else if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"crossdissolve"]) {
            transitionStyle = UIModalTransitionStyleCrossDissolve;
        }
    }
    self.inAppBrowserViewController.modalTransitionStyle = transitionStyle;

    //prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([self.inAppBrowserViewController.webView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[self.inAppBrowserViewController.webView scrollView]).bounces = NO;
        } else {
            for (id subview in self.inAppBrowserViewController.webView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }

    // use of beforeload event
    if([browserOptions.beforeload isKindOfClass:[NSString class]]){
        _beforeload = browserOptions.beforeload;
    }else{
        _beforeload = @"yes";
    }
    _waitForBeforeload = ![_beforeload isEqualToString:@""];

    [self.inAppBrowserViewController navigateTo:url];
    if([windowState isUnhiding]){
        return;
    }
    if (!browserOptions.hidden) {
        [self showWithHiddenAs:YES withNoAnimate:browserOptions.hidden];
    } else {
        [windowState hidden];
    }
}

- (void)show:(CDVInvokedUrlCommand*)command{
    [self showWithHiddenAs:NO withNoAnimate:NO];
}

- (void)showWithHiddenAs:(BOOL)hidden withNoAnimate:(BOOL)noAnimate
{
    BOOL initHidden = hidden && noAnimate;


    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (_previousStatusBarStyle != -1) {
        NSLog(@"Tried to show IAB while already shown");
        return;
    }

    if (!initHidden)
    {
        _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    }

    __block CDVInAppBrowserNavigationController* nav = [[CDVInAppBrowserNavigationController alloc]
                                                        initWithRootViewController:self.inAppBrowserViewController];
    nav.orientationDelegate = self.inAppBrowserViewController;
    nav.navigationBarHidden = YES;
    nav.modalPresentationStyle = self.inAppBrowserViewController.modalPresentationStyle;

    __weak CDVWKInAppBrowser* weakSelf = self;

    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.inAppBrowserViewController != nil) {
            float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf->tmpWindow) {
                CGRect frame = [[UIScreen mainScreen] bounds];
                if(initHidden && osVersion < 11){
                   frame.origin.x = -10000;
                }
                strongSelf->tmpWindow = [[UIWindow alloc] initWithFrame:frame];
            }
            UIViewController *tmpController = [[UIViewController alloc] initWithNibName:nil bundle:nil];

            [strongSelf->tmpWindow setRootViewController:tmpController];
            [strongSelf->tmpWindow setWindowLevel:UIWindowLevelNormal];

            if(!initHidden || osVersion < 11){
                [self->tmpWindow makeKeyAndVisible];
            }
            [tmpController presentViewController:nav animated:!noAnimate completion:nil];
        }
    });
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [self hide];
}

- (void)openInCordovaWebView:(NSURL*)url withOptions:(NSString*)options
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

#ifdef __CORDOVA_4_0_0
    // the webview engine itself will filter for this according to <allow-navigation> policy
    // in config.xml for cordova-ios-4.0
    [self.webViewEngine loadRequest:request];
#else
    if ([self.commandDelegate URLIsWhitelisted:url]) {
        [self.webView loadRequest:request];
    } else { // this assumes the InAppBrowser can be excepted from the white-list
        [self openInInAppBrowser:url withOptions:options];
    }
#endif
}

-(void)hide
{
    // Set tmpWindow to hidden to make main webview responsive to touch again
    // https://stackoverflow.com/questions/4544489/how-to-remove-a-uiwindow
    self->tmpWindow.hidden = YES;

    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
    }
    if (_previousStatusBarStyle == -1) {
        NSLog(@"Tried to hide IAB while already hidden");
        return;
    }

    _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;

    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.inAppBrowserViewController != nil) {
            self->_previousStatusBarStyle = -1;
            [self.inAppBrowserViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
    [windowState hidden];
}


// TODO: KPB - Figure out why this is different to current
// FROM OUR FORK
// - (void)openInSystem:(NSURL*) url {
//     if ([[UIApplication sharedApplication] canOpenURL:url]) {
//         [[UIApplication sharedApplication] openURL:url];
//     } else { // handle any custom schemes to plugins
//         [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
//     }
// }
- (void)openInSystem:(NSURL*)url
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)loadAfterBeforeload:(CDVInvokedUrlCommand*)command
{
    NSString* urlStr = [command argumentAtIndex:0];

    if ([_beforeload isEqualToString:@""]) {
        NSLog(@"unexpected loadAfterBeforeload called without feature beforeload=get|post");
    }
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to invoke loadAfterBeforeload on IAB after it was closed.");
        return;
    }
    if (urlStr == nil) {
        NSLog(@"loadAfterBeforeload called with nil argument, ignoring.");
        return;
    }

    NSURL* url = [NSURL URLWithString:urlStr];
    //_beforeload = @"";
    _waitForBeforeload = NO;
    [self.inAppBrowserViewController navigateTo:url];
}

- (void)unHide:(CDVInvokedUrlCommand*)command {
    [windowState unhide];
    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
    }


    self.cordovaPluginResultProxy.callbackId = command.callbackId;
    [self openUrl:url targets:target withOptions:options];
}

- (void)update:(CDVInvokedUrlCommand*)command {
    [[CDVWKInAppBrowser getInstance] update:command];
    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    BOOL show = [[command argumentAtIndex:3] boolValue];

    self.cordovaPluginResultProxy.callbackId = command.callbackId;
    if (show && [windowState isHidden]){
        [windowState unhide];
    }
    [self openUrl:url targets:target withOptions:options];
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    // Ensure a message handler bridge is created to communicate with the CDVWKInAppBrowserViewController
    [self evaluateJavaScript: [NSString stringWithFormat:@"(function(w){if(!w._cdvMessageHandler) {w._cdvMessageHandler = function(id,d){w.webkit.messageHandlers.%@.postMessage({d:d, id:id});}}})(window)", IAB_BRIDGE_NAME]];    
    [self evaluateJavaScript: [NSString stringWithFormat:@"(function(w){if(!w.JavaScriptBridgeInterfaceObject){w.JavaScriptBridgeInterfaceObject = {respond: function(response) { if(response !== []) { w.webkit.messageHandlers.%@.postMessage({data:response}); } } };}})(window)", JAVASCRIPT_BRIDGE_NAME]];

    if (jsWrapper != nil) {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
        NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self evaluateJavaScript:jsToInject];
        }
    } else {
        [self evaluateJavaScript:source];
    }
}

//Synchronus helper for javascript evaluation
- (void)evaluateJavaScript:(NSString *)script {
    __block NSString* _script = script;
    [self.inAppBrowserViewController.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ : %@", error.localizedDescription, _script);
        }
    }];
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvMessageHandler('%@',JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;

    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)sendBridgeResult:(NSString*) data {
    [self.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"bridgeresponse", @"data":data}];
}

 - (void)handleNativeResultWithString:(NSString*) jsonString {
     NSLog(@"%@", jsonString);
     NSError* __autoreleasing error = nil;
     NSData* jsonData = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
     
     if(error != nil)
     {
         NSLog(@"The poll script return value is not parsable by native code");
         [self sendBridgeResult:jsonString];
     }

 	if([jsonData isKindOfClass:[NSArray class]])
    {
        // It is a non-natively handled event
        [self sendBridgeResult:jsonString];
        return;
    }
     
     if(![jsonData isKindOfClass:[NSDictionary class]]){
         // It is a non-natively handled event
         [self sendBridgeResult:jsonString];
         return;
     }

     NSDictionary * actionDictionary = (NSDictionary*) jsonData;
     NSData* inAppBrowserAction = [actionDictionary valueForKey: @"InAppBrowserAction"];
     if(inAppBrowserAction == nil)
     {
        NSLog(@"The poll script return value looked like it should be handled natively, but the action was null - returning json directly to JS");
        [self sendBridgeResult:jsonString];
        return;
     }
     if(![inAppBrowserAction isKindOfClass:[NSString class]])
     {
        NSLog(@"The poll script return value looked like it should be handled natively, but the action was not a string - returning json directly to JS");
        [self sendBridgeResult:jsonString];
        return;
     }
     
     NSString *action = (NSString *)inAppBrowserAction;

     if([action caseInsensitiveCompare:@"close"] == NSOrderedSame) {
         [self.inAppBrowserViewController close];
         return;
     } else if ([action caseInsensitiveCompare:@"hide"] == NSOrderedSame) {
         [self hide];
         return;
     } else {
         NSLog(@"The poll script return is correctly formed to be handled natively, but the action '%@' is not handled - returning json directly to JS", action);
         [self sendBridgeResult:jsonString];
     }
 }

 - (void)handleNativeResult:(NSURL*) url {
     if(![[url host] isEqualToString:@"poll"]) {
         return;
     }

     NSString* scriptResult = [url path];
     if ((scriptResult == nil) || ([scriptResult length] < 2)) {
         return;
     }


     NSString* jsonString = [scriptResult substringFromIndex:1]; //This is still the path of the URL, strip leading '/'
     [self handleNativeResultWithString:jsonString];

 }

 - (BOOL)isWhitelistedCustomScheme:(NSString*)scheme {
     NSString* allowedSchemesPreference = [self settingForKey:@"AllowedSchemes"];
     if (allowedSchemesPreference == nil || [allowedSchemesPreference isEqualToString:@""]) {
         // Preference missing.
         return NO;
     }
     for (NSString* allowedScheme in [allowedSchemesPreference componentsSeparatedByString:@","]) {
         if ([allowedScheme isEqualToString:scheme]) {
             return YES;
         }
     }
     return NO;
 }

/**
 * The message handler bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 */
- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    NSURL* url = navigationAction.request.URL;
    NSURL* mainDocumentURL = navigationAction.request.mainDocumentURL;
    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];
    BOOL shouldStart = YES;
    BOOL useBeforeLoad = NO;
    NSString* httpMethod = navigationAction.request.HTTPMethod;
    NSString* errorMessage = nil;

    if([_beforeload isEqualToString:@"post"]){
        //TODO handle POST requests by preserving POST data then remove this condition
        errorMessage = @"beforeload doesn't yet support POST requests";
    }
    else if(isTopLevelNavigation && (
           [_beforeload isEqualToString:@"yes"]
       || ([_beforeload isEqualToString:@"get"] && [httpMethod isEqualToString:@"GET"])
    // TODO comment in when POST requests are handled
    // || ([_beforeload isEqualToString:@"post"] && [httpMethod isEqualToString:@"POST"])
    )){
        useBeforeLoad = YES;
    }

    // When beforeload, on first URL change, initiate JS callback. Only after the beforeload event, continue.
    if (_waitForBeforeload && useBeforeLoad) {
        [self.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"beforeload", @"url":[url absoluteString]}];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if(errorMessage != nil){
        NSLog(@"%@", errorMessage);
        [self.cordovaPluginResultProxy sendErrorWithMessageAsDictionary:@{@"type":@"loaderror", @"url":[url absoluteString], @"code": @"-1", @"message": errorMessage}];
    }

     // See if the url uses the 'gap-iab' protocol. If so, the host should be the id of a callback to execute,
     // and the path, if present, should be a JSON-encoded value to pass to the callback.
     if ([[url scheme] isEqualToString:@"gap-iab"]) {
         [self handleInjectedScriptCallBack: url];
         shouldStart = NO;
     
     }
     //test for whitelisted custom scheme names like mycoolapp:// or twitteroauthresponse:// (Twitter Oauth Response)
     else if (![[url scheme] isEqualToString:@"http"] && ![[url scheme] isEqualToString:@"https"] && [self isWhitelistedCustomScheme:[url scheme]]) {
         // Send a customscheme event.
         CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                       messageAsDictionary:@{@"type":@"customscheme", @"url":[url absoluteString]}];
         [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
         [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
         shouldStart = NO;
     }
     // if is an app store link, let the system handle it, otherwise it fails to load it
     else if ([[ url scheme] isEqualToString:@"itms-appss"] || [[ url scheme] isEqualToString:@"itms-apps"]) {
        [theWebView stopLoading];
        [self openInSystem:url];
        shouldStart = NO;
     }
     // See if the url uses the 'gap-iab-native' protocol. If so, the path should be a conform to
     // gap-iab-native://actiontype/{{URL ENCODED JSON OBJECT}}
     // Currently support: actiontype = poll, {{URL ENCODED JSON OBJECT}} = {InAppBrowserAction:'{{actionname}}'} where {{actionname}} is 'hide' or 'close'
     else if([[url scheme] isEqualToString:@"gap-iab-native"]) {
         [self handleNativeResult:url];
         shouldStart = NO;
     }
    else if (([self.cordovaPluginResultProxy hasCallbackId]) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        [self.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString]}];
    }

    if (useBeforeLoad) {
        _waitForBeforeload = YES;
    }

    if(shouldStart){
        // Fix GH-417 & GH-424: Handle non-default target attribute
        // Based on https://stackoverflow.com/a/25713070/777265
        if (!navigationAction.targetFrame){
            [theWebView loadRequest:navigationAction.request];
            decisionHandler(WKNavigationActionPolicyCancel);
        }else{
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark WKScriptMessageHandler delegate

- (void)handleInjectedScriptCallBack:(NSURL*) url {
    // NOTE the callbackId is that of the script, not the Webview.
    NSString* scriptCallbackId = [url host];
    if ([ScriptCallBackIdValidator isValid:scriptCallbackId]) {
        return;
    }
    
    CordovaPluginResultProxy* scriptPluginResultProxy =[[CordovaPluginResultProxy alloc] initWithCommanDelegate:self.commandDelegate];
    scriptPluginResultProxy.callbackId = scriptCallbackId;
    
    NSString* scriptResult = [url path];
    NSError* __autoreleasing error = nil;

    // The message should be a JSON-encoded array of the result of the script which executed.
    if (scriptResult == nil || [scriptResult length] <= 1)
    {
        [scriptPluginResultProxy sendOKWithMessageAsArray:@[]];
        return;
    }

     scriptResult = [scriptResult substringFromIndex:1];
    NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]])
    {
        [scriptPluginResultProxy sendOKWithMessageAsArray:(NSArray*)decodedResult];
        return;
    }
    [scriptPluginResultProxy sendJSONError];
 }

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if([message.body isKindOfClass:[NSDictionary class]]){
        NSDictionary* messageContent = (NSDictionary*) message.body;

        CordovaPluginResultProxy* scriptResultProxy = [[CordovaPluginResultProxy alloc] initWithCommanDelegate:self.commandDelegate];
        scriptResultProxy.callbackId = messageContent[@"id"];

        if([messageContent objectForKey:@"d"]){
            NSString* scriptResult = messageContent[@"d"];
            NSError* __autoreleasing error = nil;
            NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                [scriptResultProxy sendOKWithMessageAsArray:(NSArray*)decodedResult];
                return;
            }
            [scriptResultProxy sendJSONError];
            return;
        }

        [scriptResultProxy sendOKWithMessageAsArray:@[]];
        return;
    }

    if([self.cordovaPluginResultProxy hasCallbackId]){
        // Send a message event
        NSString* messageContent = (NSString*) message.body;
        NSError* __autoreleasing error = nil;
        NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[messageContent dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if (error == nil) {
            NSMutableDictionary* dResult = [NSMutableDictionary new];
            [dResult setValue:@"message" forKey:@"type"];
            [dResult setObject:decodedResult forKey:@"data"];
            [self.cordovaPluginResultProxy sendOKWithMessageAsDictionary: dResult];
        }
    }
}

- (void)didStartProvisionalNavigation:(WKWebView*)theWebView
{
    // NOTE: the second line was commeneted out by Apache at the time of writing.
    NSLog(@"didStartProvisionalNavigation");
//    self.inAppBrowserViewController.currentURL = theWebView.URL;
}

- (void)didFinishNavigation:(WKWebView*)theWebView
{
    if ([self.cordovaPluginResultProxy hasCallbackId]) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            if(self.inAppBrowserViewController.currentURL != nil){
                url = [self.inAppBrowserViewController.currentURL absoluteString];
            }else{
                url = @"";
            }
        }

        [self.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        if ([windowState isUnhiding]) {
            [self showWithHiddenAs:NO withNoAnimate:true];
        }
    }
}


- (void)webView:(WKWebView*)theWebView didFailNavigation:(NSError*)error
{
    if (![self.cordovaPluginResultProxy hasCallbackId]) {
        return;
    }

    if( [error code] == NSURLErrorCancelled ) {
        // NSURLErrorCancelled (code 999 ) is considered benign: it happens when the page is navigated away from
        // while loading - as happens in Italy when waiting for the payment provider to acknowledge completion
        // See http://iosdeveloperzone.com/tag/nsurlerrorcancelled/ "Suppressing Spurious Error Messages" for
        // Explanation. Few sources cite this particular error as benign.
        NSLog(@"IGNORED ERROR: %@", error); // Still log though!
        return;
    }

    NSString* url = [theWebView.URL absoluteString];
    if(url == nil){
        if(self.inAppBrowserViewController.currentURL != nil)
        {
            url = [self.inAppBrowserViewController.currentURL absoluteString];
        }
        else
        {
            url = @"";
        }
    }
    [self.cordovaPluginResultProxy sendErrorWithMessageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInteger:error.code], @"message": error.localizedDescription}];
}

// KPB - checked.
- (void)browserExit
{
    [self.cordovaPluginResultProxy sendTerminatingExitPluginResult];

    
    [self.inAppBrowserViewController.configuration.userContentController removeScriptMessageHandlerForName:IAB_BRIDGE_NAME];
    [self.inAppBrowserViewController.configuration.userContentController removeScriptMessageHandlerForName:JAVASCRIPT_BRIDGE_NAME];
    self.inAppBrowserViewController.configuration = nil;

    [self.inAppBrowserViewController.webView stopLoading];
    [self.inAppBrowserViewController.webView removeFromSuperview];
    [self.inAppBrowserViewController.webView setUIDelegate:nil];
    [self.inAppBrowserViewController.webView setNavigationDelegate:nil];
    self.inAppBrowserViewController.webView = nil;

    // Set navigationDelegate to nil to ensure no callbacks are received from it.
    self.inAppBrowserViewController.navigationDelegate = nil;
    self.inAppBrowserViewController = nil;

    // Set tmpWindow to hidden to make main webview responsive to touch again
    // Based on https://stackoverflow.com/questions/4544489/how-to-remove-a-uiwindow
    self->tmpWindow.hidden = YES;

    if (IsAtLeastiOSVersion(@"7.0")) {
        if (_previousStatusBarStyle != -1) {
            [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle];
        }
    }

    _previousStatusBarStyle = -1; // this value was reset before reapplying it. caused statusbar to stay black on ios7
}

@end //CDVWKInAppBrowser

// ***************************************************************************************************************************************************************************
#pragma mark CDVWKInAppBrowserViewController

@implementation CDVWKInAppBrowserViewController

@synthesize currentURL;

BOOL viewRenderedAtLeastOnce = FALSE;
BOOL isExiting = FALSE;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVInAppBrowserOptions*) browserOptions
{
    self = [super init];
    if (self != nil) {
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
        self.webViewUIDelegate = [[CDVWKInAppBrowserUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        [self.webViewUIDelegate setViewController:self];

        [self createViews];
    }

    return self;
}

-(void)dealloc {
    //NSLog(@"dealloc");
}

- (void)createViews
{

    // We create the views in code for primarily for ease of upgrades and not requiring an external .xib to be included

    CGRect webViewBounds = self.view.bounds;
    BOOL toolbarIsAtBottom = ![_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop];
    webViewBounds.size.height -= _browserOptions.location ? FOOTER_HEIGHT : TOOLBAR_HEIGHT;
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
#if __has_include("CDVWKProcessPoolFactory.h")
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
#endif
    
    // Inject the handler here.
    JavaScriptBridgeInterface* handler = [[JavaScriptBridgeInterface alloc] initWithHandler:^(NSString* response){
        NSLog(@"%@", response);
        [self.navigationDelegate handleNativeResultWithString:response];
    }];
    
    [configuration.userContentController addScriptMessageHandler:self name:IAB_BRIDGE_NAME]; // This is the IAB handler for execute script
    [configuration.userContentController  addScriptMessageHandler:handler name:JAVASCRIPT_BRIDGE_NAME]; // This is our handler for bridged guff.

    //WKWebView options
    configuration.allowsInlineMediaPlayback = _browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"10.0")) {
        configuration.ignoresViewportScaleLimits = _browserOptions.enableviewportscale;
        if(_browserOptions.mediaplaybackrequiresuseraction == YES){
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        }else{
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
    }else{ // iOS 9
        configuration.mediaPlaybackRequiresUserAction = _browserOptions.mediaplaybackrequiresuseraction;
    }

    self.webView = [[WKWebView alloc] initWithFrame:webViewBounds configuration:configuration];

    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];

    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self.webViewUIDelegate;
    self.webView.backgroundColor = [UIColor whiteColor];

    self.webView.clearsContextBeforeDrawing = YES;
    self.webView.clipsToBounds = YES;
    self.webView.contentMode = UIViewContentModeScaleToFill;
    self.webView.multipleTouchEnabled = YES;
    self.webView.opaque = YES;
    self.webView.userInteractionEnabled = YES;
    self.automaticallyAdjustsScrollViewInsets = YES ;
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    self.webView.allowsLinkPreview = NO;
    self.webView.allowsBackForwardNavigationGestures = NO;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
   if (@available(iOS 11.0, *)) {
       [self.webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
   }
#endif

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.alpha = 1.000;
    self.spinner.autoresizesSubviews = YES;
    self.spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
    self.spinner.clearsContextBeforeDrawing = NO;
    self.spinner.clipsToBounds = NO;
    self.spinner.contentMode = UIViewContentModeScaleToFill;
    self.spinner.frame = CGRectMake(CGRectGetMidX(self.webView.frame), CGRectGetMidY(self.webView.frame), 20.0, 20.0);
    self.spinner.hidden = NO;
    self.spinner.hidesWhenStopped = YES;
    self.spinner.multipleTouchEnabled = NO;
    self.spinner.opaque = NO;
    self.spinner.userInteractionEnabled = NO;
    [self.spinner stopAnimating];

    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;

    UIBarButtonItem* flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    UIBarButtonItem* fixedSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceButton.width = 20;

    float toolbarY = toolbarIsAtBottom ? self.view.bounds.size.height - TOOLBAR_HEIGHT : 0.0;
    CGRect toolbarFrame = CGRectMake(0.0, toolbarY, self.view.bounds.size.width, TOOLBAR_HEIGHT);

    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.alpha = 1.000;
    self.toolbar.autoresizesSubviews = YES;
    self.toolbar.autoresizingMask = toolbarIsAtBottom ? (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin) : UIViewAutoresizingFlexibleWidth;
    self.toolbar.barStyle = UIBarStyleBlackOpaque;
    self.toolbar.clearsContextBeforeDrawing = NO;
    self.toolbar.clipsToBounds = NO;
    self.toolbar.contentMode = UIViewContentModeScaleToFill;
    self.toolbar.hidden = NO;
    self.toolbar.multipleTouchEnabled = NO;
    self.toolbar.opaque = NO;
    self.toolbar.userInteractionEnabled = YES;
    if (_browserOptions.toolbarcolor != nil) { // Set toolbar color if user sets it in options
      self.toolbar.barTintColor = [self colorFromHexString:_browserOptions.toolbarcolor];
    }
    if (!_browserOptions.toolbartranslucent) { // Set toolbar translucent to no if user sets it in options
      self.toolbar.translucent = NO;
    }

    CGFloat labelInset = 5.0;
    float locationBarY = toolbarIsAtBottom ? self.view.bounds.size.height - FOOTER_HEIGHT : self.view.bounds.size.height - LOCATIONBAR_HEIGHT;

    self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelInset, locationBarY, self.view.bounds.size.width - labelInset, LOCATIONBAR_HEIGHT)];
    self.addressLabel.adjustsFontSizeToFitWidth = NO;
    self.addressLabel.alpha = 1.000;
    self.addressLabel.autoresizesSubviews = YES;
    self.addressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    self.addressLabel.backgroundColor = [UIColor clearColor];
    self.addressLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.addressLabel.clearsContextBeforeDrawing = YES;
    self.addressLabel.clipsToBounds = YES;
    self.addressLabel.contentMode = UIViewContentModeScaleToFill;
    self.addressLabel.enabled = YES;
    self.addressLabel.hidden = NO;
    self.addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumScaleFactor:")]) {
        [self.addressLabel setValue:@(10.0/[UIFont labelFontSize]) forKey:@"minimumScaleFactor"];
    } else if ([self.addressLabel respondsToSelector:NSSelectorFromString(@"setMinimumFontSize:")]) {
        [self.addressLabel setValue:@(10.0) forKey:@"minimumFontSize"];
    }

    self.addressLabel.multipleTouchEnabled = NO;
    self.addressLabel.numberOfLines = 1;
    self.addressLabel.opaque = NO;
    self.addressLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.addressLabel.textAlignment = NSTextAlignmentLeft;
    self.addressLabel.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
    self.addressLabel.userInteractionEnabled = NO;

    NSString* frontArrowString = NSLocalizedString(@"►", nil); // create arrow from Unicode char
    self.forwardButton = [[UIBarButtonItem alloc] initWithTitle:frontArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goForward:)];
    self.forwardButton.enabled = YES;
    self.forwardButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
      self.forwardButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }

    NSString* backArrowString = NSLocalizedString(@"◄", nil); // create arrow from Unicode char
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:backArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    self.backButton.enabled = YES;
    self.backButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
      self.backButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }

    // Filter out Navigation Buttons if user requests so
    if (_browserOptions.hidenavigationbuttons) {
        if (_browserOptions.lefttoright) {
            [self.toolbar setItems:@[flexibleSpaceButton, self.closeButton]];
        } else {
            [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton]];
        }
    } else if (_browserOptions.lefttoright) {
        [self.toolbar setItems:@[self.backButton, fixedSpaceButton, self.forwardButton, flexibleSpaceButton, self.closeButton]];
    } else {
        [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];
    }

    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.addressLabel];
    [self.view addSubview:self.spinner];
}

- (void) setWebViewFrame : (CGRect) frame {
    NSLog(@"Setting the WebView's frame to %@", NSStringFromCGRect(frame));
    [self.webView setFrame:frame];
}

- (void)setCloseButtonTitle:(NSString*)title : (NSString*) colorString : (int) buttonIndex
{
    // the advantage of using UIBarButtonSystemItemDone is the system will localize it for you automatically
    // but, if you want to set this yourself, knock yourself out (we can't set the title for a system Done button, so we have to create a new one)
    self.closeButton = nil;
    // Initialize with title if title is set, otherwise the title will be 'Done' localized
    self.closeButton = title != nil ? [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(close)] : [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;
    // If color on closebutton is requested then initialize with that that color, otherwise use initialize with default
    self.closeButton.tintColor = colorString != nil ? [self colorFromHexString:colorString] : [UIColor colorWithRed:60.0 / 255.0 green:136.0 / 255.0 blue:230.0 / 255.0 alpha:1];

    NSMutableArray* items = [self.toolbar.items mutableCopy];
    [items replaceObjectAtIndex:buttonIndex withObject:self.closeButton];
    [self.toolbar setItems:items];
}

- (void)showLocationBar:(BOOL)show
{
    CGRect locationbarFrame = self.addressLabel.frame;

    BOOL toolbarVisible = !self.toolbar.hidden;

    // prevent double show/hide
    if (show == !(self.addressLabel.hidden)) {
        return;
    }

    if (show) {
        self.addressLabel.hidden = NO;

        if (toolbarVisible) {
            // toolBar at the bottom, leave as is
            // put locationBar on top of the toolBar

            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= FOOTER_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no toolBar, so put locationBar at the bottom

            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        }
    } else {
        self.addressLabel.hidden = YES;

        if (toolbarVisible) {
            // locationBar is on top of toolBar, hide locationBar

            // webView take up whole height less toolBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
        } else {
            // no toolBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)showToolBar:(BOOL)show : (NSString *) toolbarPosition
{
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect locationbarFrame = self.addressLabel.frame;

    BOOL locationbarVisible = !self.addressLabel.hidden;

    // prevent double show/hide
    if (show == !(self.toolbar.hidden)) {
        return;
    }

    if (show) {
        self.toolbar.hidden = NO;
        CGRect webViewBounds = self.view.bounds;

        if (locationbarVisible) {
            // locationBar at the bottom, move locationBar up
            // put toolBar at the bottom
            webViewBounds.size.height -= FOOTER_HEIGHT;
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
            self.toolbar.frame = toolbarFrame;
        } else {
            // no locationBar, so put toolBar at the bottom
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            self.toolbar.frame = toolbarFrame;
        }

        if ([toolbarPosition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
            toolbarFrame.origin.y = 0;
            webViewBounds.origin.y += toolbarFrame.size.height;
            [self setWebViewFrame:webViewBounds];
        } else {
            toolbarFrame.origin.y = (webViewBounds.size.height + LOCATIONBAR_HEIGHT);
        }
        [self setWebViewFrame:webViewBounds];

    } else {
        self.toolbar.hidden = YES;

        if (locationbarVisible) {
            // locationBar is on top of toolBar, hide toolBar
            // put locationBar at the bottom

            // webView take up whole height less locationBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];

            // move locationBar down
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no locationBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)viewDidLoad
{
    viewRenderedAtLeastOnce = FALSE;
    [super viewDidLoad];
}

// OH MY GIDDY AUNT, use a simple word like "hide?" LOLNO not apple.
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isExiting && (self.navigationDelegate != nil) && [self.navigationDelegate respondsToSelector:@selector(browserExit)]) {
        [self.navigationDelegate browserExit];
        isExiting = FALSE;
    }
    [self.navigationDelegate.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"hidden"}];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([windowState isUnhiding])
    {
        NSString* url = @"";
        if(self.navigationDelegate.inAppBrowserViewController.currentURL != nil)
        {
            url = [self.navigationDelegate.inAppBrowserViewController.currentURL absoluteString];
        }
        [self.navigationDelegate.cordovaPluginResultProxy sendOKWithMessageAsDictionary:@{@"type":@"unhidden", @"url":url}];
    }
    [windowState displayed];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)close
{
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    self.currentURL = nil;

    __weak UIViewController* weakSelf = self;

    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        isExiting = TRUE;
        if ([weakSelf respondsToSelector:@selector(presentingViewController)]) {
            [[weakSelf presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[weakSelf parentViewController] dismissViewControllerAnimated:YES completion:nil];
        }
    });
    [windowState closed];
    [self.navigationDelegate.cordovaPluginResultProxy sendTerminatingExitPluginResult];
}

- (void)navigateTo:(NSURL*)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    if (_userAgentLockToken != 0) {
        [self.webView loadRequest:request];
    } else {
        __weak CDVWKInAppBrowserViewController* weakSelf = self;
        [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
            self->_userAgentLockToken = lockToken;
            [CDVUserAgentUtil setUserAgent:self->_userAgent lockToken:lockToken];
            [weakSelf.webView loadRequest:request];
        }];
    }
}

- (void)goBack:(id)sender
{
    [self.webView goBack];
}

- (void)goForward:(id)sender
{
    [self.webView goForward];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (IsAtLeastiOSVersion(@"7.0") && !viewRenderedAtLeastOnce) {
        viewRenderedAtLeastOnce = TRUE;
        CGRect viewBounds = [self.webView bounds];
        viewBounds.origin.y = STATUSBAR_HEIGHT;
        viewBounds.size.height = viewBounds.size.height - STATUSBAR_HEIGHT;
        self.webView.frame = viewBounds;
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
    }
    [self rePositionViews];

    [super viewWillAppear:animated];
}

//
// On iOS 7 the status bar is part of the view's dimensions, therefore it's height has to be taken into account.
// The height of it could be hardcoded as 20 pixels, but that would assume that the upcoming releases of iOS won't
// change that value.
//
- (float) getStatusBarOffset {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    float statusBarOffset = IsAtLeastiOSVersion(@"7.0") ? MIN(statusBarFrame.size.width, statusBarFrame.size.height) : 0.0;
    return statusBarOffset;
}

- (void) rePositionViews {
    if ([_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, TOOLBAR_HEIGHT, self.webView.frame.size.width, self.webView.frame.size.height)];
        [self.toolbar setFrame:CGRectMake(self.toolbar.frame.origin.x, [self getStatusBarOffset], self.toolbar.frame.size.width, self.toolbar.frame.size.height)];
    }
}

// Helper function to convert hex color string to UIColor
// Assumes input like "#00FF00" (#RRGGBB).
// Taken from https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)theWebView didStartProvisionalNavigation:(WKNavigation *)navigation{

    // loading url, start spinner, update back/forward

    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;

    NSLog(_browserOptions.hidespinner ? @"Yes" : @"No");
    if(!_browserOptions.hidespinner) {
        [self.spinner startAnimating];
    }

    return [self.navigationDelegate didStartProvisionalNavigation:theWebView];
}

- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    NSURL *mainDocumentURL = navigationAction.request.mainDocumentURL;

    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];

    if (isTopLevelNavigation) {
        self.currentURL = url;
    }

    [self.navigationDelegate webView:theWebView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    // update url, stop spinner, update back/forward

    self.addressLabel.text = [self.currentURL absoluteString];
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    theWebView.scrollView.contentInset = UIEdgeInsetsZero;

    [self.spinner stopAnimating];

    // Work around a bug where the first time a PDF is opened, all UIWebViews
    // reload their User-Agent from NSUserDefaults.
    // This work-around makes the following assumptions:
    // 1. The app has only a single Cordova Webview. If not, then the app should
    //    take it upon themselves to load a PDF in the background as a part of
    //    their start-up flow.
    // 2. That the PDF does not require any additional network requests. We change
    //    the user-agent here back to that of the CDVViewController, so requests
    //    from it must pass through its white-list. This *does* break PDFs that
    //    contain links to other remote PDF/websites.
    // More info at https://issues.apache.org/jira/browse/CB-2225
    BOOL isPDF = NO;
    //TODO webview class
    //BOOL isPDF = [@"true" isEqualToString :[theWebView evaluateJavaScript:@"document.body==null"]];
    if (isPDF) {
        [CDVUserAgentUtil setUserAgent:_prevUserAgent lockToken:_userAgentLockToken];
    }

    [self.navigationDelegate didFinishNavigation:theWebView];
    [windowState canOpen];
}

- (void)webView:(WKWebView*)theWebView failedNavigation:(NSString*) delegateName withError:(nonnull NSError *)error{
    // log fail message, stop spinner, update back/forward
    NSLog(@"webView:%@ - %ld: %@", delegateName, (long)error.code, [error localizedDescription]);

    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    [self.spinner stopAnimating];

    self.addressLabel.text = NSLocalizedString(@"Load Error", nil);

    [self.navigationDelegate webView:theWebView didFailNavigation:error];
    [windowState canOpen];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailNavigation" withError:error];
}

- (void)webView:(WKWebView*)theWebView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailProvisionalNavigation" withError:error];
}

#pragma mark WKScriptMessageHandler delegate
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if (![message.name isEqualToString:IAB_BRIDGE_NAME]) {
        return;
    }
    //NSLog(@"Received script message %@", message.body);
    [self.navigationDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

#pragma mark CDVScreenOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }

    return 1 << UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }

    return YES;
}


@end //CDVWKInAppBrowserViewController
