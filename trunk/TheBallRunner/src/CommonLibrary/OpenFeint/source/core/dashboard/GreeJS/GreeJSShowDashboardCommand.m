//
// Copyright 2012 GREE, Inc.
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

#import "GreeJSShowDashboardCommand.h"
#import "GreePlatform.h"
#import "UIViewController+GreeAdditions.h"

#define kGreeJSLaunchDashboardCommandCallbackFunction @"callback"


@interface GreeJSShowDashboardCommand ()
@property (nonatomic, retain) NSDictionary *parameters;

- (void)callback:(id)callback withErrorMessage:(NSString*)error;
@end

@implementation GreeJSShowDashboardCommand

@synthesize parameters = _parameters;

#pragma mark - Object lifecycle
- (void)dealloc {
  [_parameters release];
  
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"show_dashboard";
}

- (void)execute:(NSDictionary *)params
{
  UIViewController *viewController = [self viewControllerWithRequiredBaseClass:nil];

  NSString *URLString = [params objectForKey:@"URL"];
  
  if (URLString == nil) {
    [self
      callback:[params objectForKey:kGreeJSLaunchDashboardCommandCallbackFunction]
      withErrorMessage:@"No URL provided"];
    return;
  }
  
  NSURL *URL = [NSURL URLWithString:URLString];

  if (URL == nil) {
    [self
      callback:[params objectForKey:kGreeJSLaunchDashboardCommandCallbackFunction]
      withErrorMessage:@"Invalid URL provided"];
    return;
  }
     
  [viewController presentGreeDashboardWithBaseURL:URL delegate:self animated:YES completion:nil];
  self.parameters = params;
}

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p>",
    NSStringFromClass([self class]),
    self];
}

#pragma mark - Internal Methods
- (void)callback:(id)callback withErrorMessage:(NSString*)error
{
  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithBool:NO], @"result",
    error, @"error",
    nil];
    
  [[self.environment handler]
    callback:callback
    params:callbackParameters];
    
  [self callback];
}

#pragma mark - GreeDashboardViewControllerDelegate
- (void)dashboardCloseButtonPressed:(id)dashboardViewController {
  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  [[self.environment handler]
    callback:[self.parameters objectForKey:kGreeJSLaunchDashboardCommandCallbackFunction]
    params:callbackParameters];
  [self callback];
  
  UIViewController *viewController = [self viewControllerWithRequiredBaseClass:nil];
  [viewController dismissGreeDashboardAnimated:YES completion:nil];
}

@end
