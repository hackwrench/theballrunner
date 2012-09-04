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


#import <QuartzCore/QuartzCore.h>
#import "GreeError.h"
#import "GreeJSCommandFactory.h"
#import "GreeJSHandler.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "GreeWebSession.h"
#import "NSURL+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "GreeError+Internal.h"
#import "GreePlatform+Internal.h"
#import "UIWebView+GreeAdditions.h"
#import "GreeWebSessionRegenerator.h"
#import "GreeLogger.h"
#import "GreeSettings.h"

#define kGreePopupActivityIndicatorFileName @"GreePopupActivityIndicator.html"
#define kGreePopupConnectionFailureFileName @"GreePopupConnectionFailure.html"

#undef HEXCOLOR
#define HEXCOLOR(n) (((float)n)/ 255.0f)

CGFloat const GreePopupNavigationBarPortraitHeight = 40.0f;
CGFloat const GreePopupNavigationBarLandscapeHeight = 32.0f;

@interface GreePopupNavigationBar : UIView
@end
@implementation GreePopupNavigationBar
@end


@interface GreePopupBackButton : UIButton
@end
@implementation GreePopupBackButton
@end


@interface GreePopupCloseButton : UIButton
@end
@implementation GreePopupCloseButton
@end


@interface GreePopupView () <UIWebViewDelegate>
- (void)adjustContentView;
- (void)setTitleFromTitleTagInWebView:(UIWebView*)aWebView;
- (void)setTitleAsGreeLogo;
@end


@implementation GreePopupView
@synthesize containerView;
@synthesize contentView;
@synthesize navigationBar;
@synthesize titleLabel;
@synthesize logoImage;
@synthesize backButton;
@synthesize closeButton;
@synthesize webView;
@synthesize delegate;
@synthesize commandEnvironment = _commandEnvironment;
@synthesize handler;

#pragma mark - Object Lifecycle

- (void)awakeFromNib {
  currentRequest = nil;
  connectionFailureContentsLoading = NO;

  self.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.6f];
  self.titleLabel.text = @"";
  self.backButton.hidden = YES;
  handler = [[GreeJSHandler alloc] init];
  handler.webView = self.webView;
}

- (void)dealloc {
  [handler release];
  [currentRequest release];
  self.webView.delegate = nil, [webView release];
  [navigationBar release];
  [closeButton release];
  [titleLabel release];
  [logoImage release];
  [backButton release];
  [contentView release];
  [containerView release];
  [super dealloc];
}


#pragma mark - Public Interface

- (void)show
{
  __block GreePopupView* nonRetainedSelf = self;
  CGAffineTransform transform = self.contentView.transform;
  
  // Prompt a layout if we haven't been already
  [self adjustContentView];
  
  self.contentView.transform = CGAffineTransformScale(transform, 0.05f, 0.05f);
  self.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.0f];
  
  if ([self.delegate respondsToSelector:@selector(popupViewWillLaunch)]) {
    [self.delegate popupViewWillLaunch];
  }
	  
  [UIView animateWithDuration:0.12 animations:^{
    nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 1.1, 1.1);
    nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.4f];
  } completion:^(BOOL finished) {
    [UIView animateWithDuration:0.15 animations:^{
      nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 0.93f, 0.93f);
      nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.5f];
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:0.15 animations:^{
        nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 1.f, 1.f);
        nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.6f];
      } completion:^(BOOL finished) {
      
        if ([nonRetainedSelf.delegate respondsToSelector:@selector(popupViewDidLaunch)]) {
          [nonRetainedSelf.delegate popupViewDidLaunch];
        }
      }];
    }];
  }];
}

- (void)dismiss
{
  [self.webView stopLoading];
   
  __block GreePopupView* nonRetainedSelf = self;
  CGAffineTransform transform = self.contentView.transform;
  
  if ([self.delegate respondsToSelector:@selector(popupViewWillDismiss)]) {
    [self.delegate popupViewWillDismiss];
  }
  
  [UIView animateWithDuration:0.23 animations:^{
    nonRetainedSelf.contentView.transform = CGAffineTransformScale(transform, 0.01, 0.01);
    nonRetainedSelf.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.1f];
  } completion:^(BOOL finished) {
    nonRetainedSelf.hidden = YES;
    if ([nonRetainedSelf.delegate respondsToSelector:@selector(popupViewDidDismiss)]) {
      [nonRetainedSelf.delegate popupViewDidDismiss];
    }
  }];
}

- (IBAction)closeButtonTapped:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(popupViewDidCancel)]) {
    [self.delegate popupViewDidCancel];
  }
}

- (IBAction)backButtonTapped:(id)sender
{
  if ([self.webView canGoBack]) {
    [self.webView goBack];
  }
}

- (void)setTitleWithString:(NSString*)aTitleString
{
  self.logoImage.hidden = YES;
  self.titleLabel.text = aTitleString;
}


#pragma mark - UIVIew Overrides

- (void)layoutSubviews {
  CGFloat navBarHeight;

  if (self.superview.bounds.size.width > self.superview.bounds.size.height) {
    navBarHeight = GreePopupNavigationBarLandscapeHeight;
  } else {
    navBarHeight = GreePopupNavigationBarPortraitHeight;
  }

  self.navigationBar.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, navBarHeight);
  self.webView.frame = CGRectMake(0, navBarHeight, self.contentView.bounds.size.width, self.contentView.bounds.size.height - navBarHeight);
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p navigationBar:%@ webView:%@ delegate:%@>", NSStringFromClass([self class]), self, navigationBar, webView, delegate];
}

#pragma mark - Internal Methods

- (void)adjustContentView
{
  self.contentView.layer.cornerRadius = 5.f;
  self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setTitleFromTitleTagInWebView:(UIWebView*)aWebView
{
  NSString *title = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (0 < [title length]) {
    titleLabel.text = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    logoImage.hidden = YES;
  } else {
    [self setTitleAsGreeLogo];
  }
}

- (void)setTitleAsGreeLogo
{
  titleLabel.text = @"";
  logoImage.hidden = NO;
}

-(void)showActivityIndicator
{
  [self.webView showActivityIndicator];
}

- (void)showHTTPErrorMessage:(NSError*)anError
{
  [self.webView showHTTPErrorMessage:anError loadingFlag:&connectionFailureContentsLoading
    bodyStreamExhaustedErrorFilePath:[[NSBundle greePlatformCoreBundle] pathForResource:kGreePopupConnectionFailureFileName ofType:nil]];
}

#pragma mark - UIWebViewDelegate Methods

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)anError
{
  if (([anError.domain isEqualToString:@"WebKitErrorDomain"] && [anError code] == 102) ||
      [anError code] == kCFURLErrorCancelled) {
    // Ignore it.
    return;
  }

  GreeLog(@"url:%@ error:%@", aWebView.request.URL, anError);
  
	if ([self.delegate respondsToSelector:@selector(popupViewWebView:didFailLoadWithError:)]) {
		[self.delegate popupViewWebView:aWebView didFailLoadWithError:anError];
	} else {
    [self showHTTPErrorMessage:anError];
  }
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)aNavigationType
{
  NSString* body = [[NSString alloc] initWithData:aRequest.HTTPBody encoding:NSUTF8StringEncoding];
	GreeLog(@"request:%@\n"
          @"navigationType:%d\n"
          @"headers:%@\n"
          @"body length:%d",
          aRequest, aNavigationType, [aRequest allHTTPHeaderFields], [body length]);
  [body release];

  if([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingShowConnectionServer]){
    [webView attachLabelWithURL:aRequest.URL position:GreeWebViewUrlLabelPositionTop];
  }

  if (connectionFailureContentsLoading) {
    connectionFailureContentsLoading = NO;
    return YES;
  }
  
  NSURL *aURL = aRequest.URL;
  // handle reload
  if (aNavigationType == UIWebViewNavigationTypeReload) {
    if ([aURL isGreeDomain] == YES || [aURL isGreeErrorURL] == YES) {
      if ([self.delegate respondsToSelector:@selector(popupViewWebViewReload:)]) {
        [self.delegate popupViewWebViewReload:aWebView];
        return NO;
      }
    }
  }

  // handle an activity indicator
  if ([self.delegate respondsToSelector:@selector(popupViewShouldDisplayActivityIndicator)] &&
      ![self.delegate popupViewShouldDisplayActivityIndicator]) {
    // fall through
  } else {
    if ([[aURL scheme] isEqualToString:@"http"] || [[aURL scheme] isEqualToString:@"https"]) {
      if (!currentRequest) {
        currentRequest = [aRequest retain];
        [self performSelector:@selector(showActivityIndicator) withObject:nil afterDelay:0.f];
        [self.webView performSelector:@selector(loadRequest:) withObject:currentRequest afterDelay:0.2f];
        return NO;
      } else {
        [currentRequest release], currentRequest = nil;
      }
    }
  }
  
  // handle web session regenerating if necessary
  id regenerator =
  [GreeWebSessionRegenerator generatorIfNeededWithRequest:aRequest webView:self.webView delegate:self.delegate
    showHttpErrorBlock:^(NSError* error) {
      [self showHTTPErrorMessage:error];
    }
  ];
  if (regenerator) {
    return NO;
  }

  // handle any proton commands
  if ([GreeJSHandler executeCommandFromRequest:aRequest handler:self.handler environment:self.commandEnvironment]) {
    return NO;
  }
  
  // handle self url cheme
  if ([aURL isSelfGreeURLScheme]) {
    if ([self.delegate respondsToSelector:@selector(popupURLHandlerReceivedSelfURLSchemeRequest:)]) {
      [self.delegate popupURLHandlerReceivedSelfURLSchemeRequest:aRequest];
      return NO;
    }
  }
  
  // handle Ad URL
  if ([aURL isGreeAdRedirectorURL]) {
    if ([self.delegate respondsToSelector:@selector(popupURLHandlerReceivedAdRedirectorURLRequest:)]) {
      [self.delegate popupURLHandlerReceivedAdRedirectorURLRequest:aRequest];
      return NO;
    } else {
      
    }
  }
  
  // can be any url handling if necessary
  if ([self.delegate respondsToSelector:@selector(popupURLHandlerWebView:shouldStartLoadWithRequest:navigationType:)]) {
    return [self.delegate popupURLHandlerWebView:aWebView shouldStartLoadWithRequest:aRequest navigationType:aNavigationType];
  }

  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
	if ([self.delegate respondsToSelector:@selector(popupViewWebViewDidStartLoad:)]) {
		[self.delegate popupViewWebViewDidStartLoad:aWebView];
	}

  // Set a flag in window.name to distinguish proton clients from mobile safari.
  // Set every time because external page have the potential of change window.name.
  [aWebView stringByEvaluatingJavaScriptFromString:@"window.name='protonApp'"];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
  NSURL *anURL = aWebView.request.URL;
  GreeLog(@"anURL:%@", anURL);

  if ([self.delegate respondsToSelector:@selector(popupViewHowDoesSetTitle)]) {
    switch ([self.delegate popupViewHowDoesSetTitle]) {
      case GreePopupViewTitleSettingMethodNothing:
        // nothing to do
        break;
      case GreePopupViewTitleSettingMethodLogoOnly:
        [self setTitleAsGreeLogo];
        break;
      case GreePopupViewTitleSettingMethodFromTitleTagInContents:
      default:
        [self setTitleFromTitleTagInWebView:aWebView];
        break;
    }
  } else {
    [self setTitleFromTitleTagInWebView:aWebView];
  }

  if ([self.delegate respondsToSelector:@selector(popupViewShouldAcceptEmptyBody)] &&
      [self.delegate popupViewShouldAcceptEmptyBody]) {
    // fall through
  } else {
    // occur an error if body content is empty when http result is 200 OK
    NSString *htmlContents = [aWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName(\"body\")[0].innerHTML"];
    if ([anURL.scheme isEqualToString:@"http"] && [htmlContents length] == 0) {
      NSDictionary *aParameter = [NSDictionary dictionaryWithObject:anURL forKey:@"NSErrorFailingURLKey"];
      NSError *anError = [[[NSError alloc] initWithDomain:GreeErrorDomain code:GreeErrorCodeBadDataFromServer userInfo:aParameter] autorelease];
      [self showHTTPErrorMessage:anError];
    }
	}

  // can be any contents handling if necessary
  NSString *aLastPathComponent = [anURL lastPathComponent];
  if (![aLastPathComponent isEqualToString:kGreePopupActivityIndicatorFileName]) {
    if ([self.delegate respondsToSelector:@selector(popupViewWebViewDidFinishLoad:)]) {
      [self.delegate popupViewWebViewDidFinishLoad:aWebView];
    }
  }

}

@end

