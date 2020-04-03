#pragma mark ******************** PORTED
#import <WebKit/WebKit.h>

// KPB -this is purely our code
//@protocol JavaScriptBridgeInterface <JSExport>
//- (NSString *)respond: (NSString*)response;
//@end
//
//@interface JavaScriptBridgeInterfaceObject : NSObject<JavaScriptBridgeInterface>
//- (id)initWithCallback:(void (^)(NSString*))callback;
//@end


@interface JavaScriptBridgeInterface : NSObject<WKScriptMessageHandler> {
    id responseDelegate;
}

- (id)initWithHandler:(void(^)(NSString*))handler;

@end
