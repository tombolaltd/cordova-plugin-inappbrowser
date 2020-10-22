#import "CordovaPluginResultProxy.h"
#import <Cordova/CDVPluginResult.h>

@implementation CordovaPluginResultProxy

-(id)initWithCommanDelegate:(id <CDVCommandDelegate>)commandDelegate {
    self = [super init];
    if( self = [super init])
    {
        self.commandDelegate = commandDelegate;
    }
    return self;
}

- (bool)hasCallbackId
{
    return self.callbackId != nil;
}

#pragma mark OK results
- (void)sendOK
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsString:(NSString*)theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsArray:(NSArray*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsInt:(int) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsNSInteger:(NSInteger) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSInteger:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsNSUInteger:(NSUInteger) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSUInteger:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsDouble:(double) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageBool:(BOOL) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsDictionary:(NSDictionary*)theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsArrayBuffer:(NSData*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKWithMessageAsMultipart:(NSArray*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:theMessage];
    [self sendOKPluginResult:pluginResult];
}

#pragma mark JSONErrors
- (void)sendJSONError
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
    [self sendOKPluginResult:pluginResult];
}

#pragma mark Error results
- (void)sendError
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsString:(NSString*)theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsArray:(NSArray*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsArray:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsInt:(int) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsNSInteger:(NSInteger) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsNSInteger:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsNSUInteger:(NSUInteger) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsNSUInteger:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsDouble:(double) theMessage;
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageBool:(BOOL) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsBool:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsDictionary:(NSDictionary*)theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsArrayBuffer:(NSData*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsArrayBuffer:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendErrorWithMessageAsMultipart:(NSArray*) theMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsMultipart:theMessage];
    [self sendOKPluginResult:pluginResult];
}

- (void)sendOKPluginResult:(CDVPluginResult*)pluginResult
{
    if ([self hasCallbackId])
    {
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)sendTerminatingExitPluginResult
{
    if ([self hasCallbackId])
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"type":@"exit"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        self.callbackId = nil;
    }
}

@end
