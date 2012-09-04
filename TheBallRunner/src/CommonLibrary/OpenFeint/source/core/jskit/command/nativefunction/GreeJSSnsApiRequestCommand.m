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

#import "GreeJSSnsApiRequestCommand.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeSettings.h"
#import "AFNetworking.h"
#import "JSONKit.h"

@implementation GreeJSSnsApiRequestCommand

static NSString* snsApiEndpoint = @"/";

+ (NSString *)name
{
  return @"snsapi_request";
}

- (void)execute:(NSDictionary *)params
{
  __block GreeJSSnsApiRequestCommand *command = [self retain]; // Released when result is returned.

  NSString *url = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSnsApi];
  NSURL* u = [NSURL URLWithString:snsApiEndpoint relativeToURL:[NSURL URLWithString:url]];
  NSString *requestData = [params objectForKey:@"request"];
  const char *dataBytes = [requestData UTF8String];
  NSData *data = requestData ? [NSData dataWithBytes:dataBytes length:strlen(dataBytes)] : [NSData data];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:u];
  request.HTTPMethod = @"POST";
  request.HTTPShouldHandleCookies = YES;
  request.HTTPBody = data;
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  GreeHTTPClient* client = [GreePlatform sharedInstance].httpClient;
  
  [client performRequest:request parameters:nil
   success:^(GreeAFHTTPRequestOperation *operation, id responseObject){
     NSString *data = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] autorelease];
     NSDictionary *results = [data greeMutableObjectFromJSONString];
     [[command.environment handler] callback:[params objectForKey:@"success"] params:results];
     [command callback];
     [self release];
   }
   failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
     NSString *responseString = operation.responseString ? operation.responseString : nil;
     NSArray *results = [NSArray arrayWithObjects:
                         [[NSNumber numberWithInteger:operation.response.statusCode] stringValue],
                         [error localizedDescription],
                         [responseString greeMutableObjectFromJSONString],
                         nil];
     [[command.environment handler] callback:[params objectForKey:@"failure"] arguments:results];
     [command callback];
     [self release];
   }];
}

@end
