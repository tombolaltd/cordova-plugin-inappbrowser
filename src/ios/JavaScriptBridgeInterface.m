#import "JavaScriptBridgeInterface.h"

@implementation JavaScriptBridgeInterfaceObject
	void (^callbackFunction) (NSString*);

	- (id)initWithCallback:(void (^)(NSString*))callbackBlock; {
	 	self = [super init];
	    if (self) {
	        // Any custom setup work goes here
	        callbackFunction = callbackBlock;
	    }

    	return self;
	}

	- (NSString*)respond:(NSString*)response {
		if([response isEqualToString:@"[]"]){
			return response;
		}

		callbackFunction(response);
		return response;
	}
@end
