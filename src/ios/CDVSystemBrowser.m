#import "CDVSystemBrowser.h"
#import <Cordova/CDVPluginResult.h>

@implementation CDVSystemBrowser

const int INITIAL_STATUS_BAR_STYLE = -1;

-(void) openUrl:(NSString*)url {
        CDVPluginResult* pluginResult;

    if (url != nil) {
    #ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
    #else
        NSURL* baseUrl = [self.webView.request URL];
    #endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];

        if ([[UIApplication sharedApplication] canOpenURL:absoluteUrl]) {
            [[UIApplication sharedApplication] openURL:absoluteUrl];
        } else {
            // handle any custom schemes to plugins
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:absoluteUrl]];
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:[self callbackId]];
}

 - (void)open:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString* url = [command argumentAtIndex:0];

    __weak CDVSystemBrowser* weakSelf = self;

    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf openUrl:url];
    });
}

@end
