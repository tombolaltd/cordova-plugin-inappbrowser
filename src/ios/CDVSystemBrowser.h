#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

@interface CDVSystemBrowser : CDVPlugin { }

@property (nonatomic, copy) NSString* callbackId;

- (void)open:(CDVInvokedUrlCommand*)command;

@end
