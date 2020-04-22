//
//  ScriptCallBackIdValidator.m
//  IABTester
//
//  Created by Keith Barrow on 03/04/2020.
//

#import <Foundation/Foundation.h>
#import "JavaScriptBridgeResonseParser.h"


@implementation JavaScriptBridgeResonseParser

    static NSDictionary* _handlers;
    
    + (void)initializeWithCallbacks:(NSDictionary*)handlers {
        if(!_handlers)
        {
            _handlers = handlers;
        }
    }

    + (BOOL)peformActionNatively:(NSString*)action
    {
        action = [action lowercaseString];
        void(^callback)(void) = [_handlers objectForKey:[action lowercaseString]];
        if (callback == nil)
        {
            NSLog(@"The poll script return is correctly formed to be handled natively, but the action '%@' is not handled - returning json directly to JS", action);
            return NO;
        }
        callback();
        return YES;
    }

    + (NSString*)parse:(NSString*)jsonString
    {
        if (jsonString == nil || [jsonString  isEqual: @"[]"] || [jsonString isEqual:@"[[]]"])
        {
            return nil;
        }

        NSError* __autoreleasing error = nil;
        NSArray* jsonData = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if(error != nil)
        {
            NSLog(@"The poll script return value is not parsable by native code - returning json directly to JS");
            return jsonString;
        }

        // This code is predicated on the immediate event being the only thing in the array - this should be handled by the injected polling script.
        NSData* inAppBrowserAction = [((NSArray*)jsonData[0]) valueForKey: @"InAppBrowserAction"];
        if(inAppBrowserAction != nil  && [inAppBrowserAction isKindOfClass:[NSString class]])
        {
            NSString* action = (NSString*)inAppBrowserAction;
            if( [JavaScriptBridgeResonseParser peformActionNatively:action])
            {
                return nil; // Succefully handled in native, do not pass event back to the host.
            }
        }
        return jsonString;
    }
@end
