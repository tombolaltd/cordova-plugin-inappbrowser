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

#import <Cordova/CDVPluginResult.h>
#import "CDVInAppBrowser.h"
#import "CDVInAppBrowserOptions.h"
#import "CDVWKInAppBrowser.h"

@implementation CDVInAppBrowser

- (void)pluginInitialize
{
    // default values

#if __has_include("CDVWKWebViewEngine.h")
    self.wkwebviewavailable = YES;
#else
    self.wkwebviewavailable = NO;
#endif
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    printf('open');
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    CDVInAppBrowserOptions* browserOptions = [CDVInAppBrowserOptions parseOptions:options];
    if(!self.wkwebviewavailable){
        printf("load_error fired");
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:@{@"type":@"loaderror", @"message": @"wkwebview is mandatory but but no plugin that supplies a WKWebView engine is present"}] callbackId:command.callbackId];
        return;
    }
    [[CDVWKInAppBrowser getInstance] open:command];
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] close:command];
}


- (void)show:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] show:command];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] hide:command];
}


- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] injectScriptCode:command];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] injectScriptFile:command];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] injectStyleCode:command];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] injectStyleFile:command];
}

- (void)loadAfterBeforeload:(CDVInvokedUrlCommand*)command
{
    [[CDVWKInAppBrowser getInstance] loadAfterBeforeload:command];
}

- (void)unHide:(CDVInvokedUrlCommand*)command {
    [[CDVWKInAppBrowser getInstance] unHide:command];
}

- (void)update:(CDVInvokedUrlCommand*)command {
    [[CDVWKInAppBrowser getInstance] update:command];
}

@end