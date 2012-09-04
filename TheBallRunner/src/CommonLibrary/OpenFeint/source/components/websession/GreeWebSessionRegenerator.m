//
// Copyright 2011 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GreeWebSessionRegenerator.h"
#import "NSURL+GreeAdditions.h"
#import "GreePopupURLHandler.h"
#import "NSString+GreeAdditions.h"
#import "GreeWebSession.h"
#import "GreeError.h"
#import "GreeError+Internal.h"

@interface GreeWebSessionRegenerator ()
@property (nonatomic, readwrite, copy) GreeWebSessionRegeneratorShowHttpErrorBlock showHttpErrorBlock;
@property (nonatomic, readwrite, assign) int webSessionRegeneratingCount;
@property (nonatomic, readwrite, retain) UIWebView* webView;
@property (nonatomic, readwrite, retain) NSURL* backToRequest;
@end

@implementation GreeWebSessionRegenerator
@synthesize showHttpErrorBlock = _showHttpErrorBlock;
@synthesize webSessionRegeneratingCount = _webSessionRegeneratingCount;
@synthesize webView = _webView;

@synthesize backToRequest = _backToRequest;
#pragma mark - Object Lifecycle

+ (id)generatorIfNeededWithRequest:(NSURLRequest*)request webView:(UIWebView*)webView delegate:(NSObject<GreePopupURLHandlerDelegate>*)delegate showHttpErrorBlock:(GreeWebSessionRegeneratorShowHttpErrorBlock)showHttpErrorBlock
{
  NSURL *aURL = request.URL;
  if ([aURL isGreeLoginURL]) {
    if ([delegate respondsToSelector:@selector(popupURLHandlerShouldRegenerateWebSession)] &&
        [delegate popupURLHandlerShouldRegenerateWebSession] == NO) {
    } else {
      GreeWebSessionRegenerator* regenerator = [[[[self class] alloc] init] autorelease];
      regenerator.showHttpErrorBlock = showHttpErrorBlock;
      regenerator.webSessionRegeneratingCount = 0;
      regenerator.webView = webView;
      NSDictionary* aParams = [[request.URL query] greeDictionaryFromQueryString];
      NSString* backto = [aParams objectForKey:@"backto"];
      NSString* backToUrlString = [backto greeURLDecodedString];
      if (backToUrlString) {
        regenerator.backToRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:backToUrlString]];
        [regenerator performSelector:@selector(handleWebSessionRegenerating:) withObject:regenerator.backToRequest afterDelay:1.f];
      }      
      return regenerator;
    }
  }
  return nil;
}

- (void)dealloc
{
  Block_release(_showHttpErrorBlock);
  [_webView release];
  [_backToRequest release];
  [super dealloc];
}

#pragma mark - NSObject Overrides
#pragma mark - Internal Methods

-(void)handleWebSessionRegenerating:(id)aRequest
{
  [GreeWebSession regenerateWebSessionWithBlock:^(NSError* error) {
    if (!error) {
      [self performSelectorOnMainThread:@selector(handleWebSessionRegenerated:) withObject:aRequest waitUntilDone:NO];
    } else {
      if (error.code == GreeErrorCodeWebSessionNeedReAuthorize) {
        NSDictionary *aParameter = [NSDictionary dictionaryWithObject:((NSURLRequest *)aRequest).URL forKey:@"NSErrorFailingURLKey"];
        NSError *anError = [[[NSError alloc] initWithDomain:GreeErrorDomain code:GreeErrorCodeNetworkError userInfo:aParameter] autorelease];
        _showHttpErrorBlock(anError);
      } else {
        _webSessionRegeneratingCount += 1;
        if (_webSessionRegeneratingCount < 5) {
          [self performSelector:@selector(handleWebSessionRegenerating:) withObject:aRequest afterDelay:4.f];
        } else {
          NSDictionary *aParameter = [NSDictionary dictionaryWithObject:((NSURLRequest *)aRequest).URL forKey:@"NSErrorFailingURLKey"];
          NSError *anError = [[[NSError alloc] initWithDomain:GreeErrorDomain code:GreeErrorCodeNetworkError userInfo:aParameter] autorelease];
          _showHttpErrorBlock(anError);
        }
      }
    }
  }];
}

-(void)handleWebSessionRegenerated:(id)aRequest
{
	[_webView loadRequest:aRequest];
}

#pragma mark - Public Interface

@end
