#pragma mark ******************** WIP
# import "JavaScriptBridgeInterface.h"

@implementation JavaScriptBridgeInterface

void (^responseHandler)(NSString*);

- (id)initWithHandler:(void(^)(NSString*))handler {
    self = [super init];
    responseHandler = handler;
    return self;
}
// KPB -this is purely our code
//	void (^callbackFunction) (NSString*);
//
//	- (id)initWithCallback:(void (^)(NSString*))callbackBlock; {
//	 	self = [super init];
//	    if (self) {
//	        // Any custom setup work goes here
//	        callbackFunction = callbackBlock;
//	    }
//
//    	return self;
//	}
//
//	- (NSString*)respond:(NSString*)response {
//		if([response isEqualToString:@"[]"]){
//			return response;
//		}
//
//		callbackFunction(response);
//		return response;
//	}



//- (void)handleNativeResultWithString:(NSString*) jsonString {
//   NSError* __autoreleasing error = nil;
//    NSData* jsonData = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
//
//   if(error != nil || ![jsonData isKindOfClass:[NSArray class]]){
//        NSLog(@"The poll script return value looked like it shoud be handled natively, but errror or was badly formed - returning json directly to JS");
//        [self sendBridgeResult:jsonString];
//        return;
//    }
//
//    NSArray * array = (NSArray*) jsonData;
//    NSData* inAppBrowserAction = [array[0] valueForKey: @"InAppBrowserAction"];
//    if(inAppBrowserAction == nil  || ![inAppBrowserAction isKindOfClass:[NSString class]]) {
//        [self sendBridgeResult:jsonString];
//        return;
//    }
//
//    NSString *action = (NSString *)inAppBrowserAction;
//    if(action ==nil) {
//        NSLog(@"The poll script return value looked like it shoud be handled natively, but was not formed correctly (empty when cast) - returning json directly to JS");
//        [self sendBridgeResult:jsonString];
//        return;
//    }
//
//    if([action caseInsensitiveCompare:@"close"] == NSOrderedSame) {
//        [self.inAppBrowserViewController close];
//        return;
//    } else if ([action caseInsensitiveCompare:@"hide"] == NSOrderedSame) {
//        [self hide];
//        return;
//    } else {
//        NSLog(@"The poll script return value looked like it shoud be handled natively, but was not formed correctly (unhandled action) - returning json directly to JS");
//        [self sendBridgeResult:jsonString];
//    }
//}


- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message {
    NSLog(@"%@", message.name);
    NSLog(@"%@", message.body);
    responseHandler(message.body);
}
@end
