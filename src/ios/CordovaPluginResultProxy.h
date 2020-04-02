#import <Cordova/CDVCommandDelegate.h>


@interface CordovaPluginResultProxy: NSObject
    @property (nonatomic, weak) id <CDVCommandDelegate> commandDelegate;
    @property (nonatomic, copy) NSString* callbackId;

    - (id)initWithCommanDelegate:(id <CDVCommandDelegate>)commandDelegate;
    - (BOOL)hasCallbackId;

    - (void)sendError;
    - (void)sendErrorWithMessageAsString:(NSString*) theMessage;
    - (void)sendErrorWithMessageAsArray:(NSArray*) theMessage;
    - (void)sendErrorWithMessageAsInt:(int) theMessage;
    - (void)sendErrorWithMessageAsNSInteger:(NSInteger) theMessage;
    - (void)sendErrorWithMessageAsNSUInteger:(NSUInteger) theMessage;
    - (void)sendErrorWithMessageAsDouble:(double) theMessage;
    - (void)sendErrorWithMessageBool:(BOOL) theMessage;
    - (void)sendErrorWithMessageAsDictionary:(NSDictionary*) theMessage;
    - (void)sendErrorWithMessageAsArrayBuffer:(NSData*) theMessage;
    - (void)sendErrorWithMessageAsMultipart:(NSString*) theMessage;

    - (void)sendJSONError;

    - (void)sendOK;
    - (void)sendOKWithMessageAsString:(NSString*) theMessage;
    - (void)sendOKWithMessageAsArray:(NSArray*) theMessage;
    - (void)sendOKWithMessageAsInt:(int) theMessage;
    - (void)sendOKWithMessageAsNSInteger:(NSInteger) theMessage;
    - (void)sendOKWithMessageAsNSUInteger:(NSUInteger) theMessage;
    - (void)sendOKWithMessageAsDouble:(double) theMessage;
    - (void)sendOKWithMessageBool:(BOOL) theMessage;
    - (void)sendOKWithMessageAsDictionary:(NSDictionary*) theMessage;
    - (void)sendOKWithMessageAsArrayBuffer:(NSData*) theMessage;
    - (void)sendOKWithMessageAsMultipart:(NSString*) theMessage;

    - (void)sendTerminatingExitPluginResult;
@end
