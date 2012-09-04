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

#import "NSHTTPCookieStorage+GreeAdditions.h"

@implementation NSHTTPCookieStorage (GreeAdditions)

+ (void)greeSetCookieWithParams:(NSDictionary*)params domain:(NSString*)domain
{
  NSArray* keys = [params allKeys];
  for (int n=0; n< keys.count; ++n) {
    NSString* key = [keys objectAtIndex:n];
    NSString* value = [params objectForKey:key];
    [self greeSetCookie:value forName:key domain:domain];
  }
}

+ (void)greeSetCookie:(NSString*)value forName:(NSString*)name domain:(NSString*)domain 
{	
	NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat:@".%@", domain], @"Domain", 
    @"2031-03-05 08:03:02 +0900" , @"Expires",
    @"/" ,@"Path",
    name, @"Name",
    value, @"Value",
    nil
    ]];
	[cookieStorage setCookie:cookie];  
}

+ (NSString*)greeGetCookieValueWithName:(NSString*)name domain:(NSString*)domain 
{
  NSArray* cookies = [self greeCookiesWithDomain:domain];
	for (NSHTTPCookie *cookie in cookies) {
		if ([[cookie name] isEqualToString:name]) {
			return [cookie value];
		}
	}
	return nil;
}

+ (void)greeDeleteCookieWithName:(NSString*)name domain:(NSString*)domain
{  
 	NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray* cookies = [self greeCookiesWithDomain:domain];
	for (NSHTTPCookie *cookie in cookies) {
		if ([[cookie name] isEqualToString:name]) {
      [cookieStorage deleteCookie:cookie];
		}
	}
}

+ (NSArray*)greeCookiesWithDomain:(NSString*)domain
{
	NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSString* urlString = [NSString stringWithFormat:@"http://%@/",domain];
  NSURL* url = [NSURL URLWithString:urlString];
	return  [cookieStorage cookiesForURL:url];  
}

@end
