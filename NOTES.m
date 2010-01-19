/* Reverse-engineered parts of NSURLConnection implementation as of 10.5.8 */

@implementation NSURLConnection

// cfConn is the NSURLConnection's underlying CFURLConnectionRef

+ (id) connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	// Notice: [NSURLConnection alloc] instead of [self alloc]
	return [[[NSURLConnection alloc] initWithRequest:request delegate:delegate] autorelease];
}

- (id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	return [self _initWithRequest:request delegate:delegate usesCache:YES maxContentLength:0LL startImmediately:YES];
}

// NSURLConnection private designated initializer
- (id) _initWithRequest:(NSURLRequest *)request delegate:(id)delegate usesCache:(BOOL)usesCache maxContentLength:(long long)maxContentLength startImmediately:(BOOL)startImmediately
{
	// various initializations ...
	if (startImmediately)
	{
		// Documentation says: "At creation, a connection is scheduled on the current thread [...] in the default mode."
		// Implementation says this is unfortunately not true when startImmediately == NO
		CFURLConnectionScheduleWithRunLoop(cfConn, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		CFURLConnectionStart(cfConn);
	}
	return self;
}

- (void) scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode
{
	CFURLConnectionScheduleWithRunLoop(cfConn, [runLoop getCFRunLoop], mode);
}

- (void) start
{
	CFURLConnectionStart(cfConn);
}

@end
