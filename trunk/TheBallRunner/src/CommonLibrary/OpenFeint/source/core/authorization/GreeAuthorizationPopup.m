//
// Copyright 2010-2011 GREE, inc.
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

#import "GreeAuthorizationPopup.h"
#import "NSBundle+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeGlobalization.h"

@interface GreeAuthorizationPopup ()
- (void)loadHTMLString:(NSString*)aUrlString withErrorString:(NSString*)errorString;
@end

@implementation GreeAuthorizationPopup
@synthesize selfURLSchemeHandlingBlock= _selfURLSchemeHandlingBlock;
@synthesize defaultURLSchemeHandlingBlock = _defaultURLSchemeHandlingBlock;
@synthesize didFailLoadHandlingBlock = _didFailLoadHandlingBlock;
@synthesize didFinishLoadHandlingBlock = _didFinishLoadHandlingBlock;
@synthesize lastRequest = _lastRequest;

#pragma mark - Object Lifcycle
- (void)dealloc
{
  [_selfURLSchemeHandlingBlock release];
  [_defaultURLSchemeHandlingBlock release];
  [_didFailLoadHandlingBlock release];
  [_didFinishLoadHandlingBlock release];
  [_lastRequest release];
  [super dealloc];
}

#pragma mark - GreePopupURLHandlerDelegate
-(BOOL)popupURLHandlerShouldRegenerateWebSession
{
  return NO;
}

-(void)popupURLHandlerReceivedSelfURLSchemeRequest:(NSURLRequest *)aRequest
{
  if(self.selfURLSchemeHandlingBlock)
    self.selfURLSchemeHandlingBlock(aRequest);
}

-(BOOL)popupURLHandlerWebView:(UIWebView *)aWebView 
   shouldStartLoadWithRequest:(NSURLRequest *)aRequest 
               navigationType:(UIWebViewNavigationType)aNavigationType
{
  if (self.defaultURLSchemeHandlingBlock) {
    return self.defaultURLSchemeHandlingBlock(aRequest);
  }
  return YES;
}

#pragma mark - GreePopupViewDelegate
-(void)popupViewWebView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)anError
{
  if (self.didFailLoadHandlingBlock)
    _didFailLoadHandlingBlock();

  if (self.lastRequest) {
    NSString* lastLocation = [[self.lastRequest URL] absoluteString];
    [self loadHTMLString:lastLocation withErrorString:nil];
  } else {
    [self.popupView showHTTPErrorMessage:anError];
  }
}

-(void)popupViewWebViewDidFinishLoad:(UIWebView *)aWebView
{  
  if (self.didFinishLoadHandlingBlock)
    _didFinishLoadHandlingBlock(aWebView.request);
}

#pragma mark - Public Interface
- (void)loadErrorPageOnNotWebAccess
{
  NSString* lastLocation = [[self.lastRequest URL] absoluteString];
  [self loadHTMLString:lastLocation withErrorString:nil];
}

- (void)loadErrorPageOnOAuthError:(NSString*)errorString
{
  NSString* lastLocation = [[self.lastRequest URL] absoluteString];
  [self loadHTMLString:lastLocation withErrorString:errorString];
}

- (void)closeButtonHidden:(BOOL)aHidden
{
  //self.popupView.closeButton.hidden = aHidden;
}

- (void)showActivityIndicator
{
  [self.popupView showActivityIndicator];
}

- (GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle
{
  return GreePopupViewTitleSettingMethodLogoOnly;
}

#pragma mark - Internal Method
- (void)loadHTMLString:(NSString*)aUrlString withErrorString:(NSString *)errorString
{
  NSString *aFilePath = [[NSBundle greePlatformCoreBundle] pathForResource:@"GreePopupConnectionFailure.html" ofType:nil];
  NSString *aHtmlString = [NSString stringWithContentsOfFile:aFilePath encoding:NSUTF8StringEncoding error:nil];
  aHtmlString = [aHtmlString 
    greeStringByReplacingHtmlLocalizedStringWithKey:@"GreePopupConnectionFailure#reload" 
    withString:GreePlatformString(@"GreePopupConnectionFailure#reload", @"reload")];
  if (!errorString) {
    aHtmlString = [aHtmlString 
      greeStringByReplacingHtmlLocalizedStringWithKey:@"GreePopupConnectionFailure#checkSignalStrength" 
      withString:GreePlatformString(@"GreePopupConnectionFailure#checkSignalStrength", @"Please check the signal strength and try to connect again.")];
  } else {
    aHtmlString = [aHtmlString 
      greeStringByReplacingHtmlLocalizedStringWithKey:@"GreePopupConnectionFailure#checkSignalStrength" 
      withString:errorString];
  }
  NSString* content = aHtmlString;
  if (aUrlString) {
    aUrlString  = [NSString stringWithFormat:@"'%@'",aUrlString];
    content = [aHtmlString stringByReplacingOccurrencesOfString:@"location.pathname.substring(1)" withString:aUrlString];
  }
  [self loadHTMLString:content baseURL:[NSURL fileURLWithPath:aFilePath]];    
}


@end
