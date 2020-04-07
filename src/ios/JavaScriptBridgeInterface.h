#import <WebKit/WebKit.h>

@interface JavaScriptBridgeInterface : NSObject<WKScriptMessageHandler> {
    id responseDelegate;
}

- (id)initWithHandler:(void(^)(NSString*))handler;

@end
