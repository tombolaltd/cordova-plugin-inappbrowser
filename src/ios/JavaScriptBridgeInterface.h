#pragma mark ******************** PORTED
#import <JavaScriptCore/JavaScriptCore.h>

// KPB -this is purely our code
@protocol JavaScriptBridgeInterface <JSExport>
- (NSString *)respond: (NSString*)response;
@end

@interface JavaScriptBridgeInterfaceObject : NSObject<JavaScriptBridgeInterface>
- (id)initWithCallback:(void (^)(NSString*))callback;
@end