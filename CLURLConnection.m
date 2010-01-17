#import "CLURLConnection.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NSString *const HTTPErrorDomain = @"HTTPErrorDomain";

static inline NSString* httpErrorDescription(NSInteger statusCode)
{
	NSString *errorDescription = NSLocalizedStringFromTable(@"Unknowns Status Code", @"HTTPErrorCodes", "HTTP Unknown Status Code");

	if (statusCode == 400)
		errorDescription = NSLocalizedStringFromTable(@"Bad Request",                     @"HTTPErrorCodes", "HTTP Status Code 400");
	else if (statusCode == 401)
		errorDescription = NSLocalizedStringFromTable(@"Unauthorized",                    @"HTTPErrorCodes", "HTTP Status Code 401");
	else if (statusCode == 402)
		errorDescription = NSLocalizedStringFromTable(@"Payment Required",                @"HTTPErrorCodes", "HTTP Status Code 402");
	else if (statusCode == 403)
		errorDescription = NSLocalizedStringFromTable(@"Forbidden",                       @"HTTPErrorCodes", "HTTP Status Code 403");
	else if (statusCode == 404)
		errorDescription = NSLocalizedStringFromTable(@"Not Found",                       @"HTTPErrorCodes", "HTTP Status Code 404");
	else if (statusCode == 405)
		errorDescription = NSLocalizedStringFromTable(@"Method Not Allowed",              @"HTTPErrorCodes", "HTTP Status Code 405");
	else if (statusCode == 406)
		errorDescription = NSLocalizedStringFromTable(@"Not Acceptable",                  @"HTTPErrorCodes", "HTTP Status Code 406");
	else if (statusCode == 407)
		errorDescription = NSLocalizedStringFromTable(@"Proxy Authentication Required",   @"HTTPErrorCodes", "HTTP Status Code 407");
	else if (statusCode == 408)
		errorDescription = NSLocalizedStringFromTable(@"Request Timeout",                 @"HTTPErrorCodes", "HTTP Status Code 408");
	else if (statusCode == 409)
		errorDescription = NSLocalizedStringFromTable(@"Conflict",                        @"HTTPErrorCodes", "HTTP Status Code 409");
	else if (statusCode == 410)
		errorDescription = NSLocalizedStringFromTable(@"Gone",                            @"HTTPErrorCodes", "HTTP Status Code 410");
	else if (statusCode == 411)
		errorDescription = NSLocalizedStringFromTable(@"Length Required",                 @"HTTPErrorCodes", "HTTP Status Code 411");
	else if (statusCode == 412)
		errorDescription = NSLocalizedStringFromTable(@"Precondition Failed",             @"HTTPErrorCodes", "HTTP Status Code 412");
	else if (statusCode == 413)
		errorDescription = NSLocalizedStringFromTable(@"Request Entity Too Large",        @"HTTPErrorCodes", "HTTP Status Code 413");
	else if (statusCode == 414)
		errorDescription = NSLocalizedStringFromTable(@"Request-URI Too Long",            @"HTTPErrorCodes", "HTTP Status Code 414");
	else if (statusCode == 415)
		errorDescription = NSLocalizedStringFromTable(@"Unsupported Media Type",          @"HTTPErrorCodes", "HTTP Status Code 415");
	else if (statusCode == 416)
		errorDescription = NSLocalizedStringFromTable(@"Requested Range Not Satisfiable", @"HTTPErrorCodes", "HTTP Status Code 416");
	else if (statusCode == 417)
		errorDescription = NSLocalizedStringFromTable(@"Expectation Failed",              @"HTTPErrorCodes", "HTTP Status Code 417");
	else if (statusCode == 418)
		errorDescription = NSLocalizedStringFromTable(@"I'm a teapot",                    @"HTTPErrorCodes", "HTTP Status Code 418");
	else if (statusCode == 422)
		errorDescription = NSLocalizedStringFromTable(@"Unprocessable Entity",            @"HTTPErrorCodes", "HTTP Status Code 422");
	else if (statusCode == 423)
		errorDescription = NSLocalizedStringFromTable(@"Locked",                          @"HTTPErrorCodes", "HTTP Status Code 423");
	else if (statusCode == 424)
		errorDescription = NSLocalizedStringFromTable(@"Failed Dependency",               @"HTTPErrorCodes", "HTTP Status Code 424");
	else if (statusCode == 425)
		errorDescription = NSLocalizedStringFromTable(@"Unordered Collection",            @"HTTPErrorCodes", "HTTP Status Code 425");
	else if (statusCode == 426)
		errorDescription = NSLocalizedStringFromTable(@"Upgrade Required",                @"HTTPErrorCodes", "HTTP Status Code 426");
	else if (statusCode == 449)
		errorDescription = NSLocalizedStringFromTable(@"Retry With",                      @"HTTPErrorCodes", "HTTP Status Code 449");
	else if (statusCode == 500)
		errorDescription = NSLocalizedStringFromTable(@"Internal Server Error",           @"HTTPErrorCodes", "HTTP Status Code 500");
	else if (statusCode == 501)
		errorDescription = NSLocalizedStringFromTable(@"Not Implemented",                 @"HTTPErrorCodes", "HTTP Status Code 501");
	else if (statusCode == 502)
		errorDescription = NSLocalizedStringFromTable(@"Bad Gateway",                     @"HTTPErrorCodes", "HTTP Status Code 502");
	else if (statusCode == 503)
		errorDescription = NSLocalizedStringFromTable(@"Service Unavailable",             @"HTTPErrorCodes", "HTTP Status Code 503");
	else if (statusCode == 504)
		errorDescription = NSLocalizedStringFromTable(@"Gateway Timeout",                 @"HTTPErrorCodes", "HTTP Status Code 504");
	else if (statusCode == 505)
		errorDescription = NSLocalizedStringFromTable(@"HTTP Version Not Supported",      @"HTTPErrorCodes", "HTTP Status Code 505");
	else if (statusCode == 506)
		errorDescription = NSLocalizedStringFromTable(@"Variant Also Negotiates",         @"HTTPErrorCodes", "HTTP Status Code 506");
	else if (statusCode == 507)
		errorDescription = NSLocalizedStringFromTable(@"Insufficient Storage",            @"HTTPErrorCodes", "HTTP Status Code 507");
	else if (statusCode == 509)
		errorDescription = NSLocalizedStringFromTable(@"Bandwidth Limit Exceeded",        @"HTTPErrorCodes", "HTTP Status Code 509");
	else if (statusCode == 510)
		errorDescription = NSLocalizedStringFromTable(@"Not Extended",                    @"HTTPErrorCodes", "HTTP Status Code 510");

	return errorDescription;
}



@interface CLURLConnectionDelegate : NSObject
{
	BOOL connectionFailed;
	id delegate;
	NSMutableSet *selectors;
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@implementation CLURLConnectionDelegate

- (id) initWithDelegate:(id)theDelegate
{
	self = [super init];
	if (self != nil) {
		delegate = [theDelegate retain];

		selectors = [[NSMutableSet alloc] init];
		Method *methods = NULL;
		unsigned int methodCount = 0;
		methods = class_copyMethodList([self class], &methodCount);
		for (unsigned int i = 0; i < methodCount; i++) {
			const char *methodName = sel_getName(method_getName(methods[i]));
			[selectors addObject:[NSString stringWithCString:methodName encoding:NSASCIIStringEncoding]];
		}
		free(methods);
	}
	return self;
}

- (void) dealloc
{
	[delegate release];
	[selectors release];
	[super dealloc];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	connectionFailed = NO;
	NSInteger statusCode = 0;
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
		statusCode = [(NSHTTPURLResponse*)response statusCode];

	if (statusCode >= 400)
	{
		connectionFailed = YES;
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		                             [response URL], NSURLErrorKey,
		                             [[response URL] absoluteString], NSErrorFailingURLStringKey,
		                             httpErrorDescription(statusCode), NSLocalizedDescriptionKey, nil];
		NSError *error = [NSError errorWithDomain:HTTPErrorDomain code:statusCode userInfo:userInfo];
		[self connection:connection didFailWithError:error];
	}
	else
	{
		if ([delegate respondsToSelector:@selector(connection:didReceiveResponse:)])
			[delegate connection:connection didReceiveResponse:response];
	}
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!connectionFailed && [delegate respondsToSelector:@selector(connection:didReceiveData:)])
		[delegate connection:connection didReceiveData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (!connectionFailed && [delegate respondsToSelector:@selector(connectionDidFinishLoading:)])
		[delegate connectionDidFinishLoading:connection];
}

- (BOOL) respondsToSelector:(SEL)selector
{
	if ([selectors containsObject:NSStringFromSelector(selector)])
		return YES;
	else
		return [delegate respondsToSelector:selector];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)selector
{
	NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:selector];

	if (methodSignature)
		return methodSignature;
	else
		return [[delegate class] instanceMethodSignatureForSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	SEL selector = [invocation selector];

	if ([delegate respondsToSelector:selector])
		[invocation invokeWithTarget:delegate];
	else
		[self doesNotRecognizeSelector:selector];
}

@end



@implementation CLURLConnection

+ (id) connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	return [[[self alloc] initWithRequest:request delegate:delegate] autorelease];
}

- (id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
	isScheduled = startImmediately;
	CLURLConnectionDelegate *clDelegate = [[[CLURLConnectionDelegate alloc] initWithDelegate:delegate] autorelease];
	return [super initWithRequest:request delegate:clDelegate startImmediately:startImmediately];
}

- (id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	return [self initWithRequest:request delegate:delegate startImmediately:YES];
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

	[super start];
}

@end
