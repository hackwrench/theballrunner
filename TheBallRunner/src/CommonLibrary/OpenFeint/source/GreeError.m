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

#import "GreeError+Internal.h"
#import "GreeGlobalization.h"
#import "AFNetworking.h"
NSString* GreeErrorDomain = @"net.gree.error";

@implementation GreeError
//note that no objects of this type are created

#pragma mark - public interface
+ (NSError*)convertToGreeError:(NSError*)input
{
  if([input.domain isEqualToString:GreeAFNetworkingErrorDomain]) {
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:input.userInfo];
    NSString* oldDescription = [input.userInfo objectForKey:NSLocalizedDescriptionKey];
    if(oldDescription) {
      [info setObject:oldDescription forKey:@"AFNetworkingErrorDescription"];
    }
    return [GreeError localizedGreeErrorWithCode:GreeErrorCodeNetworkError userInfo:info];
  }
  return input;
}

#define DEFINELOCALIZATION(code, value) [localizationTable setObject:value forKey:[NSNumber numberWithInteger:code]]
+ (NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo
{
  static NSMutableDictionary* localizationTable = nil;
  if(!localizationTable) {
    localizationTable = [[NSMutableDictionary alloc] init];
    DEFINELOCALIZATION(0, GreePlatformString(@"errorHandling.genericError.message", @"An unknown error has occurred."));
    DEFINELOCALIZATION(GreeErrorCodeNetworkError, GreePlatformString(@"errorHandling.genericNetwork.message", @"A network error has occurred."));
    DEFINELOCALIZATION(GreeErrorCodeBadDataFromServer, GreePlatformString(@"errorHandling.badData.message", @"The server returned bad data."));
    DEFINELOCALIZATION(GreeErrorCodeNotAuthorized, GreePlatformString(@"errorHandling.notAuthorized.message", @"Not an authorized user."));
    DEFINELOCALIZATION(GreeErrorCodeUserRequired, GreePlatformString(@"errorHandling.userRequired.message", @"A user is required."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeUnknown, GreePlatformString(@"errorHandling.paymentUnknownError.message", @"Payment failed for unknown reason."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeInvalidParameter, GreePlatformString(@"errorHandling.paymentInvalidParameter.message", @"Payment parameter invalid."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeUserCanceled,GreePlatformString( @"errorHandling.paymentCanceled.message", @"Payment canceled by user."));
    DEFINELOCALIZATION(GreeWalletPaymentErrorCodeTransactionExpired, GreePlatformString(@"errorHandling.paymentTransactionExpired.message", @"Payment transaction expired."));
    DEFINELOCALIZATION(GreeFriendCodeAlreadyRegistered, GreePlatformString(@"errorHandling.friendCodeAlreadyRegistered.message", @"A friend code was already registered."));
    DEFINELOCALIZATION(GreeFriendCodeAlreadyEntered, GreePlatformString(@"errorHandling.friendCodeAlreadyUsed.message", @"The friend code was already used."));
    DEFINELOCALIZATION(GreeFriendCodeNotFound, GreePlatformString(@"errorHandling.missingFriendCode.message", @"No friend code found."));
  }
  
  NSMutableDictionary* items = [NSMutableDictionary dictionaryWithDictionary:userInfo];
  NSString* localized = [localizationTable objectForKey:[NSNumber numberWithInt:errorCode]];
  if(!localized) {
    localized = [localizationTable objectForKey:[NSNumber numberWithInt:0]];
  }
  [items setObject:localized forKey:NSLocalizedDescriptionKey];
  return [NSError errorWithDomain:GreeErrorDomain code:errorCode userInfo:items];
}

+ (NSError*)localizedGreeErrorWithCode:(NSInteger)errorCode
{
  return [GreeError localizedGreeErrorWithCode:errorCode userInfo:nil];
}



@end
