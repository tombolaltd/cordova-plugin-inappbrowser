//
//  ScriptCallBackIdValidator.m
//  IABTester
//
//  Created by Keith Barrow on 03/04/2020.
//

#import <Foundation/Foundation.h>
// #import <Foundation/NSRegularExpression.h>
#import "ScriptCallBackIdValidator.h"


@implementation ScriptCallBackIdValidator
static NSRegularExpression* _callbackIdPattern;

+ (void)initialize
{
    NSError* err = nil;
    _callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:NSRegularExpressionCaseInsensitive error:&err];
    
    if (err != nil)
    {
        NSLog(@"Error: Couldn't initialize script regex");
        _callbackIdPattern = nil;
    }
}

+ (BOOL)isValid:(NSString *)callbackId
{
    if(_callbackIdPattern == nil)
    {
        // It failed to initialise - safer to say no.
        NSLog(@"Error: The script validator pattern was not initialised, returning invalid");
        return NO;
    }
    return [_callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])];
}

@end
