About
=====

`CLURLConnection` is a drop-in replacement for `NSURLConnection`. It is mostly identical to `NSURLConnection`, except in the following areas.

• Handle HTTP errors with NSError
---------------------------------
A `NSURLConnection` will send the `connection:didReceiveData:` and `connectionDidFinishLoading:` messages to its delegate, even if the HTTP status code is greater or equal to 400. The Hypertext Transfer Protocol (RFC 2616) states that 4xx and 5xx status codes are respectively client errors and server errors. A `CLURLConnection` will instead send the `connection:didFailWithError:` message to its delegate with an appropriate `NSError` of the `HTTPErrorDomain`. By default, the body of the HTTP response is ignored. Still, if you need the HTTP body, you can configure the behaviour of `CLURLConnection` instances with `-[CLURLConnection setWantsHTTPErrorBody:YES]`. You then obtain the HTTP body as `NSData` with `[[error userInfo] objectForKey:HTTPBody]`.

• Fix scheduling documentation bug
----------------------------------
`NSURLConnection` documentation states:

> At creation, a connection is scheduled on the current thread (the one where the creation takes place) in the default mode.

This is not accurate! A connection is scheduled on the current thread in the default mode only if the connection starts immediately. If you use `initWithRequest:delegate:startImmediately:` and pass `startImmediately:NO`, the connection is **not** scheduled and your application will crash. See http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg32455.html for more information.

• Automatic network activity indicator on iOS
---------------------------------------------
On iOS, applications performing network connections are supposed to indicate their activity by toggling the UIApplication `networkActivityIndicatorVisible` property. Doing this manually is tedious. `CLURLConnection` takes care of automatically showing and hiding the network activity indicator. `CLURLConnection` even toggles the network activity indicator for `NSURLConnection` instances. This is useful if you are using a library which creates `NSURLConnection` instances.

Usage
=====

First, add

    #import "CLURLConnection.h"

in your prefix header file (*_Prefix.pch), then just replace every occurrence of `[NSURLConnection alloc]` with `[CLURLConnection alloc]` and `[NSURLConnection connectionWithRequest:…]` with `[CLURLConnection connectionWithRequest:…]` in your project source code.

Nothing is required for `NSURLConnection` instances to benefit from the automatic network activity indicator, just compile the CLURLConnection.m file in your project.

Notes
=====

`CLURLConnection` is not intended to be subclassed. Subclassing would not work properly because of the `allocWithZone:` override trick. If you want to add your fixes to `NSURLConnection`, you are welcome to contribute.

Credits
=======

Thanks to [Mike Abdullah](http://twitter.com/mikeabdullah) for reviewing my code.
