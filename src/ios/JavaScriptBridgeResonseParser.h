//
//  ScriptCallBackIdValidator.h
//  IABTester
//
//  Created by Keith Barrow on 07/04/2020.
//
#ifndef JavaScriptBridgeResonseParser_h
#define JavaScriptBridgeResonseParser_h

@interface  JavaScriptBridgeResonseParser : NSObject
    + (void)initializeWithCallbacks:(NSDictionary*)handlers; // This would be better type-safe.
    + (BOOL)peformActionNatively:(NSString*)action;
    + (NSString*)parse:(NSString*)jsonString;
@end

#endif /* JavaScriptBridgeResonseParser_h */
