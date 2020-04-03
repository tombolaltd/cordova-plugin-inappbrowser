#pragma mark ******************** WIP
# import "JavaScriptBridgeInterface.h"
# import "ScriptCallBackIdValidator.h"

@implementation JavaScriptBridgeInterface

void (^responseHandler)(NSString*);

- (id)initWithHandler:(void(^)(NSString*))handler {
    self = [super init];
    responseHandler = handler;
    return self;
}

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    // TODO: KPB - this may not be correct. It works with the direct injection from the IABTester, but the pukka bridge might not.
    if(![message.body isKindOfClass:[NSDictionary class]]){
        return;
    }
    
    NSDictionary* response = (NSDictionary*)message.body;
    
    NSString* responseData = (NSString*)response[@"d"];
    NSString* callbackId = (NSString*)response[@"id"];
    if(![ScriptCallBackIdValidator isValid:callbackId]) {
        NSLog(@"The callback ID %@ is not valid for the bridge, ignoring", callbackId);
        return;
    }
    responseHandler(responseData);
}
@end
