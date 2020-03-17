#import <JavaScriptCore/JavaScriptCore.h>

@protocol JavaScriptBridgeInterface <JSExport>
- (NSString *)respond: (NSString*)response;
@end

@interface JavaScriptBridgeInterfaceObject : NSObject<JavaScriptBridgeInterface>
- (id)initWithCallback:(void (^)(NSString*))callback;
@end