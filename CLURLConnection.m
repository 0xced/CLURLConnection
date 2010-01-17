#import "CLURLConnection.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NSString *const HTTPErrorDomain = @"HTTPErrorDomain";

static inline NSString* httpErrorDescription(NSInteger statusCode)
{
	NSString *desc = NSLocalizedStringFromTable(@"Unknowns Status Code", @"HTTPErrors", "HTTP Unknown Status Code");

	switch (statusCode)
	{
		case 400: desc = NSLocalizedStringFromTable(@"Bad Request",                     @"HTTPErrors", "HTTP Status Code 400"); break;
		case 401: desc = NSLocalizedStringFromTable(@"Unauthorized",                    @"HTTPErrors", "HTTP Status Code 401"); break;
		case 402: desc = NSLocalizedStringFromTable(@"Payment Required",                @"HTTPErrors", "HTTP Status Code 402"); break;
		case 403: desc = NSLocalizedStringFromTable(@"Forbidden",                       @"HTTPErrors", "HTTP Status Code 403"); break;
		case 404: desc = NSLocalizedStringFromTable(@"Not Found",                       @"HTTPErrors", "HTTP Status Code 404"); break;
		case 405: desc = NSLocalizedStringFromTable(@"Method Not Allowed",              @"HTTPErrors", "HTTP Status Code 405"); break;
		case 406: desc = NSLocalizedStringFromTable(@"Not Acceptable",                  @"HTTPErrors", "HTTP Status Code 406"); break;
		case 407: desc = NSLocalizedStringFromTable(@"Proxy Authentication Required",   @"HTTPErrors", "HTTP Status Code 407"); break;
		case 408: desc = NSLocalizedStringFromTable(@"Request Timeout",                 @"HTTPErrors", "HTTP Status Code 408"); break;
		case 409: desc = NSLocalizedStringFromTable(@"Conflict",                        @"HTTPErrors", "HTTP Status Code 409"); break;
		case 410: desc = NSLocalizedStringFromTable(@"Gone",                            @"HTTPErrors", "HTTP Status Code 410"); break;
		case 411: desc = NSLocalizedStringFromTable(@"Length Required",                 @"HTTPErrors", "HTTP Status Code 411"); break;
		case 412: desc = NSLocalizedStringFromTable(@"Precondition Failed",             @"HTTPErrors", "HTTP Status Code 412"); break;
		case 413: desc = NSLocalizedStringFromTable(@"Request Entity Too Large",        @"HTTPErrors", "HTTP Status Code 413"); break;
		case 414: desc = NSLocalizedStringFromTable(@"Request-URI Too Long",            @"HTTPErrors", "HTTP Status Code 414"); break;
		case 415: desc = NSLocalizedStringFromTable(@"Unsupported Media Type",          @"HTTPErrors", "HTTP Status Code 415"); break;
		case 416: desc = NSLocalizedStringFromTable(@"Requested Range Not Satisfiable", @"HTTPErrors", "HTTP Status Code 416"); break;
		case 417: desc = NSLocalizedStringFromTable(@"Expectation Failed",              @"HTTPErrors", "HTTP Status Code 417"); break;
		case 418: desc = NSLocalizedStringFromTable(@"I'm a teapot",                    @"HTTPErrors", "HTTP Status Code 418"); break;
		case 422: desc = NSLocalizedStringFromTable(@"Unprocessable Entity",            @"HTTPErrors", "HTTP Status Code 422"); break;
		case 423: desc = NSLocalizedStringFromTable(@"Locked",                          @"HTTPErrors", "HTTP Status Code 423"); break;
		case 424: desc = NSLocalizedStringFromTable(@"Failed Dependency",               @"HTTPErrors", "HTTP Status Code 424"); break;
		case 425: desc = NSLocalizedStringFromTable(@"Unordered Collection",            @"HTTPErrors", "HTTP Status Code 425"); break;
		case 426: desc = NSLocalizedStringFromTable(@"Upgrade Required",                @"HTTPErrors", "HTTP Status Code 426"); break;
		case 449: desc = NSLocalizedStringFromTable(@"Retry With",                      @"HTTPErrors", "HTTP Status Code 449"); break;
		case 500: desc = NSLocalizedStringFromTable(@"Internal Server Error",           @"HTTPErrors", "HTTP Status Code 500"); break;
		case 501: desc = NSLocalizedStringFromTable(@"Not Implemented",                 @"HTTPErrors", "HTTP Status Code 501"); break;
		case 502: desc = NSLocalizedStringFromTable(@"Bad Gateway",                     @"HTTPErrors", "HTTP Status Code 502"); break;
		case 503: desc = NSLocalizedStringFromTable(@"Service Unavailable",             @"HTTPErrors", "HTTP Status Code 503"); break;
		case 504: desc = NSLocalizedStringFromTable(@"Gateway Timeout",                 @"HTTPErrors", "HTTP Status Code 504"); break;
		case 505: desc = NSLocalizedStringFromTable(@"HTTP Version Not Supported",      @"HTTPErrors", "HTTP Status Code 505"); break;
		case 506: desc = NSLocalizedStringFromTable(@"Variant Also Negotiates",         @"HTTPErrors", "HTTP Status Code 506"); break;
		case 507: desc = NSLocalizedStringFromTable(@"Insufficient Storage",            @"HTTPErrors", "HTTP Status Code 507"); break;
		case 509: desc = NSLocalizedStringFromTable(@"Bandwidth Limit Exceeded",        @"HTTPErrors", "HTTP Status Code 509"); break;
		case 510: desc = NSLocalizedStringFromTable(@"Not Extended",                    @"HTTPErrors", "HTTP Status Code 510"); break;
	}

	return desc;
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
