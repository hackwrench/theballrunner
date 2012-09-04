// UIImageView+AFNetworking.m
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import "UIImageView+AFNetworking.h"

#import "AFImageCache.h"

static char kAFImageRequestOperationObjectKey;

@interface UIImageView (_GreeAFNetworking)
@property (readwrite, nonatomic, retain, setter = greeaf_setImageRequestOperation:) GreeAFImageRequestOperation *greeaf_imageRequestOperation;
@end

@implementation UIImageView (_GreeAFNetworking)
@dynamic greeaf_imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (GreeAFNetworking)

- (GreeAFHTTPRequestOperation *)greeaf_imageRequestOperation {
    return (GreeAFHTTPRequestOperation *)objc_getAssociatedObject(self, &kAFImageRequestOperationObjectKey);
}

- (void)greeaf_setImageRequestOperation:(GreeAFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kAFImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)greeaf_sharedImageRequestOperationQueue {
    static NSOperationQueue *_imageRequestOperationQueue = nil;
    
    if (!_imageRequestOperationQueue) {
        _imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_imageRequestOperationQueue setMaxConcurrentOperationCount:8];
    }
    
    return _imageRequestOperationQueue;
}

#pragma mark -

- (void)greeSetImageWithURL:(NSURL *)url {
    [self greeSetImageWithURL:url placeholderImage:nil];
}

- (void)greeSetImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [self greeSetImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)greeSetImageWithURLRequest:(NSURLRequest *)urlRequest 
              placeholderImage:(UIImage *)placeholderImage 
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    if (![urlRequest URL] || (![self.greeaf_imageRequestOperation isCancelled] && [[urlRequest URL] isEqual:[[self.greeaf_imageRequestOperation request] URL]])) {
        return;
    } else {
        [self greeCancelImageRequestOperation];
    }
    
    UIImage *cachedImage = [[GreeAFImageCache sharedImageCache] cachedImageForURL:[urlRequest URL] cacheName:nil];
    if (cachedImage) {
        self.image = cachedImage;
        self.greeaf_imageRequestOperation = nil;
        
        if (success) {
            success(nil, nil, cachedImage);
        }
    } else {
        self.image = placeholderImage;
        
        self.greeaf_imageRequestOperation = [GreeAFImageRequestOperation imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {            
            if (self.greeaf_imageRequestOperation && ![self.greeaf_imageRequestOperation isCancelled]) {
                if (success) {
                    success(request, response, image);
                }
            
                if ([[request URL] isEqual:[[self.greeaf_imageRequestOperation request] URL]]) {
                    self.image = image;
                } else {
                    self.image = placeholderImage;
                }
            }            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            self.greeaf_imageRequestOperation = nil;
            
            if (failure) {
                failure(request, response, error);
            } 
        }];
       
        [[[self class] greeaf_sharedImageRequestOperationQueue] addOperation:self.greeaf_imageRequestOperation];
    }
}

- (void)greeCancelImageRequestOperation {
    [self.greeaf_imageRequestOperation cancel];
}

@end

#endif
