#import "CLURLConnection.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NSString *const HTTPErrorDomain = @"HTTPErrorDomain";
NSString *const HTTPBody = @"HTTPBody";


static BOOL sWantsHTTPErrorBody = NO;


static inline NSError* httpError(NSURL *responseURL, NSInteger httpStatusCode, NSData *httpBody)
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
	                         responseURL, NSURLErrorKey,
	                         responseURL, @"NSErrorFailingURLKey",
	                         [responseURL absoluteString], @"NSErrorFailingURLStringKey",
	                         [NSHTTPURLResponse localizedStringForStatusCode:httpStatusCode], NSLocalizedDescriptionKey,
	                         httpBody, HTTPBody, nil];

	return [NSError errorWithDomain:HTTPErrorDomain code:httpStatusCode userInfo:userInfo];
}



@interface CLURLConnection ()
+ (void) removeConnection:(CLURLConnection *)connection;
- (BOOL) isNSURLConnection;
@end



@interface CLURLConnectionDelegateProxy : NSProxy
{
	id delegate;
	NSInteger httpStatusCode;
	NSMutableData *httpBody;
	NSURL *responseURL;
}

- (void) connection:(CLURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(CLURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(CLURLConnection *)connection didFailWithError:(NSError *)error;
- (void) connectionDidFinishLoading:(CLURLConnection *)connection;

@end

@implementation CLURLConnectionDelegateProxy

- (id) initWithDelegate:(id)theDelegate
{
	delegate = [theDelegate retain];
	return self;
}

- (void) dealloc
{
	[delegate release];
	[super dealloc];
}

- (void) sendDelegateMessage:(SEL)connectionDelegateSelector forConnection:(CLURLConnection *)connection withObject:(id)object
{
	if ([delegate respondsToSelector:connectionDelegateSelector])
		[delegate performSelector:connectionDelegateSelector withObject:connection withObject:object];
}

- (void) connection:(CLURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	httpStatusCode = 0;
	if (![connection isNSURLConnection] && [response isKindOfClass:[NSHTTPURLResponse class]])
		httpStatusCode = [(NSHTTPURLResponse*)response statusCode];
	
	if (httpStatusCode >= 400)
	{
		if (sWantsHTTPErrorBody)
		{
			httpBody = [[NSMutableData alloc] init];
			responseURL = [[response URL] retain];
		}
		else
		{
			[connection cancel];
			[self sendDelegateMessage:@selector(connection:didFailWithError:) forConnection:connection withObject:httpError([response URL], httpStatusCode, nil)];
		}
	}
	else
		[self sendDelegateMessage:_cmd forConnection:connection withObject:response];
}

- (void) connection:(CLURLConnection *)connection didReceiveData:(NSData *)data
{
	[httpBody appendData:data];
	
	if (httpStatusCode < 400)
		[self sendDelegateMessage:_cmd forConnection:connection withObject:data];
}

- (void) connection:(CLURLConnection *)connection didFailWithError:(NSError *)error
{
	[self sendDelegateMessage:_cmd forConnection:connection withObject:error];
	
	[httpBody release]; httpBody = nil;
	[responseURL release]; responseURL = nil;
	[CLURLConnection removeConnection:connection];
}

- (void) connectionDidFinishLoading:(CLURLConnection *)connection
{
	if (httpStatusCode < 400)
		[self sendDelegateMessage:_cmd forConnection:connection withObject:nil];
	else
		[self sendDelegateMessage:@selector(connection:didFailWithError:) forConnection:connection withObject:httpError(responseURL, httpStatusCode, httpBody)];
	
	[httpBody release]; httpBody = nil;
	[responseURL release]; responseURL = nil;
	[CLURLConnection removeConnection:connection];
}

- (BOOL) respondsToSelector:(SEL)selector
{
	if (selector == @selector(connection:didReceiveResponse:) ||
	    selector == @selector(connection:didReceiveData:) ||
	    selector == @selector(connection:didFailWithError:) ||
	    selector == @selector(connectionDidFinishLoading:))
		return YES;
	else
		return [delegate respondsToSelector:selector];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)selector
{
	return [delegate methodSignatureForSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	[invocation invokeWithTarget:delegate];
}

@end

__attribute__ ((constructor)) static void initialize(void)
{
	SEL allocWithZone = @selector(allocWithZone:);
	Method CLURLConnection_allocWithZone = class_getClassMethod([CLURLConnection class], allocWithZone);
	BOOL added = class_addMethod(object_getClass([NSURLConnection class]), allocWithZone, method_getImplementation(CLURLConnection_allocWithZone), method_getTypeEncoding(CLURLConnection_allocWithZone));
	if (!added)
	{
#if TARGET_OS_IPHONE
		NSLog(@"NSURLConnection instances will not benefit from the automatic network activity indicator.");
#endif
	}
}

@implementation CLURLConnection

+ (void) setWantsHTTPErrorBody:(BOOL)wantsHTTPErrorBody
{
	sWantsHTTPErrorBody = wantsHTTPErrorBody;
}

static NSMutableSet *sConnections = nil;

+ (void) initialize
{
	if (self != [CLURLConnection class])
		return;
	
	sConnections = [[NSMutableSet alloc] init];
}

+ (void) showNetworkActivityIndicator
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideNetworkActivityIndicator)	object:nil];
#if TARGET_OS_IPHONE
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
}

+ (void) hideNetworkActivityIndicator
{
#if TARGET_OS_IPHONE
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
}

+ (void) addConnection:(CLURLConnection *)connection
{
	@synchronized(self)
	{
		if (![[connection->request URL] isFileURL])
		{
			[sConnections addObject:connection];
			[self showNetworkActivityIndicator];
		}
	}
}

+ (void) removeConnection:(CLURLConnection *)connection
{
	@synchronized(self)
	{
		[sConnections removeObject:connection];
		if ([sConnections count] == 0)
			[self performSelector:@selector(hideNetworkActivityIndicator) withObject:nil afterDelay:0.5];
	}
}

+ (id) allocWithZone:(NSZone *)zone
{
	CLURLConnection *connection = NSAllocateObject([CLURLConnection class], 0, zone);
	connection->isNSURLConnection = (self == [NSURLConnection class]);
	return connection;
}

+ (id) connectionWithRequest:(NSURLRequest *)aRequest delegate:(id)delegate
{
	return [[[self alloc] initWithRequest:aRequest delegate:delegate] autorelease];
}

- (BOOL) isNSURLConnection
{
	return isNSURLConnection;
}

- (id) initWithRequest:(NSURLRequest *)aRequest delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
	isScheduled = startImmediately;
	request = [aRequest retain];
	CLURLConnectionDelegateProxy *proxy = [[[CLURLConnectionDelegateProxy alloc] initWithDelegate:delegate] autorelease];
	if (startImmediately)
		[CLURLConnection addConnection:self];
	return [super initWithRequest:request delegate:proxy startImmediately:startImmediately];
}

- (id) initWithRequest:(NSURLRequest *)aRequest delegate:(id)delegate
{
	return [self initWithRequest:aRequest delegate:delegate startImmediately:YES];
}

- (void) dealloc
{
	[request release];
	[super dealloc];
}

- (void) scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode
{
	isScheduled = YES;
	[super scheduleInRunLoop:runLoop forMode:mode];
}

- (void) start
{
	if (!isScheduled)
		[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	[CLURLConnection addConnection:self];
	[super start];
}

- (void) cancel
{
	[CLURLConnection removeConnection:self];
	[super cancel];
}

@end
