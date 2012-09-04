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

#import "GreeKeyChain.h"

@interface GreeKeyChain ()
+ (NSDictionary*)getQueryWithName:(NSString*)name;
@end

@implementation GreeKeyChain

#pragma mark - Public Interface
+ (OSStatus)saveWithKey:(NSString*)key value:(NSString*)value 
{
  NSMutableDictionary* query = (NSMutableDictionary*)[GreeKeyChain getQueryWithName:key];
	NSData *secret = [value dataUsingEncoding:NSUTF8StringEncoding];
  
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)query, NULL);
	if (res == errSecItemNotFound) {
		[query setObject:secret forKey:(id)kSecValueData];
		res = SecItemAdd((CFDictionaryRef)query, NULL);
	}
	else if (res == errSecSuccess) {
		NSDictionary *attributeDict = [NSDictionary dictionaryWithObject:secret forKey:(id)kSecValueData];
		res = SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)attributeDict);
  }
	return res;
}

+ (id)readWithKey:(NSString*)key 
{
  NSMutableDictionary* query = (NSMutableDictionary*)[GreeKeyChain getQueryWithName:key];
	[query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
  
	NSData *secret = nil;
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef*)&secret);
	[secret autorelease];
	if (res == errSecSuccess) {
		return[[[NSString alloc] initWithData:secret encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}

+ (OSStatus)removeWithKey:(NSString*)key 
{
  NSMutableDictionary* query = (NSMutableDictionary*)[GreeKeyChain getQueryWithName:key];
	[query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
  
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)query, NULL);
	if (res == errSecItemNotFound) {
    
	} else if (res == errSecSuccess) {
		res = SecItemDelete((CFDictionaryRef)query);
		if (res != errSecSuccess) {
		}
	} else {

	}
	return res;
}

#pragma mark - Internal Method
+ (NSMutableDictionary*)getQueryWithName:(NSString*)name
{
  NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
  NSString *appid = [info objectForKey:@"CFBundleIdentifier"];
  
  return [NSMutableDictionary dictionaryWithObjectsAndKeys:
          (id)kSecClassGenericPassword, (id)kSecClass,
          appid, (id)kSecAttrService,
          name, (id)kSecAttrAccount,
          nil];  
}

@end

NSString* const GreeKeyChainAccessTokenIdentifier = @"token";
NSString* const GreeKeyChainAccessTokenSecretIdentifier = @"secret";
NSString* const GreeKeyChainUserIdIdentifier = @"userId";
NSString* const GreeKeyChainUUIDIdentifier = @"GreeUUID";

