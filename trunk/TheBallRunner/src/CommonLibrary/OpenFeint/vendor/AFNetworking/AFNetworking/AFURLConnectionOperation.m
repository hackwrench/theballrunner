// AFURLConnectionOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFURLConnectionOperation.h"

static NSUInteger const kAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

typedef enum {
    GreeAFHTTPOperationReadyState       = 1,
    GreeAFHTTPOperationExecutingState   = 2,
    GreeAFHTTPOperationFinishedState    = 3,
} GreeAFOperationState;

NSString * const GreeAFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const GreeAFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const GreeAFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^GreeAFURLConnectionOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);

static inline NSString * AFKeyPathFromOperationState(GreeAFOperationState state) {
    switch (state) {
        case GreeAFHTTPOperationReadyState:
            return @"isReady";
        case GreeAFHTTPOperationExecutingState:
            return @"isExecuting";
        case GreeAFHTTPOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

@interface GreeAFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) GreeAFOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (readwrite, nonatomic, retain) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, copy) GreeAFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) GreeAFURLConnectionOperationProgressBlock downloadProgress;
@property (readwrite, nonatomic, copy) NSURLRequest* (^redirectBlock)(NSURLRequest*, NSURLResponse*);

- (BOOL)shouldTransitionToState:(GreeAFOperationState)state;
- (void)operationDidStart;
- (void)finish;
@end

@implementation GreeAFURLConnectionOperation
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize redirectBlock = _redirectBlock;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [pool drain];
    } while (YES);
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
    
    self.state = GreeAFHTTPOperationReadyState;
	
    return self;
}

- (void)dealloc {
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_error release];
    
    [_responseData release];
    [_responseString release];
    [_dataAccumulator release];
    [_outputStream release]; _outputStream = nil;
    
    [_connection release]; _connection = nil;
	
    [_uploadProgress release];
    [_downloadProgress release];
    [_redirectBlock release];

    [super dealloc];
}

- (void)setCompletionBlock:(void (^)(void))block {
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __block id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    NSMutableURLRequest *mutableRequest = [[self.request mutableCopy] autorelease];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
}

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (void)setState:(GreeAFOperationState)state {
    if (![self shouldTransitionToState:state]) {
        return;
    }
    
    NSString *oldStateKey = AFKeyPathFromOperationState(self.state);
    NSString *newStateKey = AFKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    
    switch (state) {
        case GreeAFHTTPOperationExecutingState:
            [[NSNotificationCenter defaultCenter] postNotificationName:GreeAFNetworkingOperationDidStartNotification object:self];
            break;
        case GreeAFHTTPOperationFinishedState:
            [[NSNotificationCenter defaultCenter] postNotificationName:GreeAFNetworkingOperationDidFinishNotification object:self];
            break;
        default:
            break;
    }
}

- (BOOL)shouldTransitionToState:(GreeAFOperationState)state {    
    switch (self.state) {
        case GreeAFHTTPOperationReadyState:
            switch (state) {
                case GreeAFHTTPOperationExecutingState:
                    return YES;
                default:
                    return NO;
            }
        case GreeAFHTTPOperationExecutingState:
            switch (state) {
                case GreeAFHTTPOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case GreeAFHTTPOperationFinishedState:
            return NO;
        default:
            return YES;
    }
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
    
    if ([self isCancelled]) {
        self.state = GreeAFHTTPOperationFinishedState;
    }
}

- (NSString *)responseString {
    if (!_responseString && self.response && self.responseData) {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.response.textEncodingName));
        }
        
        self.responseString = [[[NSString alloc] initWithData:self.responseData encoding:textEncoding] autorelease];
    }
    
    return _responseString;
}

- (void)setRedirectBlock:(NSURLRequest* (^)(NSURLRequest*, NSURLResponse*))block
{
  if (_redirectBlock == block)
    return;
  
  [_redirectBlock release], _redirectBlock = nil;
  _redirectBlock = [block copy];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == GreeAFHTTPOperationReadyState;
}

- (BOOL)isExecuting {
    return self.state == GreeAFHTTPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == GreeAFHTTPOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {  
    if (![self isReady]) {
        return;
    }
    
    self.state = GreeAFHTTPOperationExecutingState;
    
    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:YES modes:[self.runLoopModes allObjects]];
}

- (void)operationDidStart {
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    [self.connection start];
}

- (void)finish {
    self.state = GreeAFHTTPOperationFinishedState;
}

- (void)cancel {
    if ([self isFinished]) {
        return;
    }
    
    [super cancel];
    
    self.cancelled = YES;
    
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)__unused connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        self.uploadProgress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = (NSHTTPURLResponse *)response;
    
    if (self.outputStream) {
        [self.outputStream open];
    } else {
        NSUInteger maxCapacity = MAX((NSUInteger)llabs(response.expectedContentLength), kAFHTTPMinimumInitialDataCapacity);
        NSUInteger capacity = MIN(maxCapacity, kAFHTTPMaximumInitialDataCapacity);
        self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data 
{
    self.totalBytesRead += [data length];
    
    if (self.outputStream) {
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = [data bytes];
            [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
        }
    } else {
        [self.dataAccumulator appendData:data];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress([data length], self.totalBytesRead, (NSInteger)self.response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {        
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        self.responseData = [NSData dataWithData:self.dataAccumulator];
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{      
    self.error = error;
    
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)__unused connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if ([self isCancelled]) {
        return nil;
    }
    
    return cachedResponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)inConnection
             willSendRequest:(NSURLRequest *)inRequest
            redirectResponse:(NSURLResponse *)inRedirectResponse
{
  if (inRedirectResponse) {
    if (self.redirectBlock) {
      NSURLRequest* newRequest = self.redirectBlock(inRequest, inRedirectResponse);
      return newRequest;
    }
  }

  return inRequest;
}

@end
