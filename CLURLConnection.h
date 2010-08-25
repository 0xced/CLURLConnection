/*
 * CLURLConnection is a drop-in replacement for NSURLConnection
 *
 * A CLURLConnection is exactly the same as a NSURLConnection, except for the
 * behavior when receiving http status codes >= 400
 *
 * A NSURLConnection will send the connection:didReceiveData: message to its
 * delegate, even if the http status code is greater or equal to 400. The
 * Hypertext Transfer Protocol (RFC 2616) states that 4xx and 5xx status codes
 * are respectively client errors and server errors. A CLURLConnection will
 * instead send the connection:didFailWithError: message to its delegate with
 * an appropriate NSError of the hereafter defined HTTPErrorDomain.
 *
 * As a bonus, CLURLConnection also fixes a crasher when calling start without
 * calling scheduleInRunLoop:forMode: first.
 * See http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg32455.html
 *
 * Tested on Mac OS X 10.5.8 and iPhone OS 3.1.2
 */

#import <Foundation/NSURLConnection.h>

extern NSString *const HTTPErrorDomain;
extern NSString *const HTTPBody;

@interface CLURLConnection : NSURLConnection
{
	@private
	BOOL isNSURLConnection;
	BOOL isScheduled;
	NSURLRequest *request;
}

+ (void) setWantsHTTPErrorBody:(BOOL)wantsHTTPErrorBody;

@end

/*
Licensed under the MIT License

Copyright (c) 2010 Cédric Luthi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
