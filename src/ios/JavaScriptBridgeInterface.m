#pragma mark ******************** WIP
# import "JavaScriptBridgeInterface.h"

@implementation JavaScriptBridgeInterface

void (^responseHandler)(NSString*);

- (id)initWithHandler:(void(^)(NSString*))handler {
    self = [super init];
    responseHandler = handler;
    return self;
}

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message
{
    // TODO: KPB - this may not be correct. It works with the direct injection from the IABTester, but the pukka bridge might not.
    if(![message.body isKindOfClass:[NSDictionary class]]){
        return;
    }
    
    NSDictionary* response = (NSDictionary*)message.body;
    
    NSString* responseData = (NSString*)response[@"data"];
    if ([responseData isEqual: @"[]"]){
        return;
    }
    
    //The callback is expecting a string as per inject script, this is wrapped in an outer array.
    NSString* canonicalisedResponse  = [NSString stringWithFormat:@"[%@]", responseData];
    responseHandler(canonicalisedResponse);
}
@end
