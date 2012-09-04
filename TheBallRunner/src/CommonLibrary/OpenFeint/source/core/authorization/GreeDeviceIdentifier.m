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

#import "GreeDeviceIdentifier.h"
#import "JSONKit.h"
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#import "NSData+GreeAdditions.h"
#import <CommonCrypto/CommonHMAC.h>
#import "GreeKeyChain.h"

static char *greeGetMacAddress(char *macAddress, char *ifName);

static NSString* kOpenFeintUserOptionLocalUser = @"OpenFeintUserOptionLocalUser";
static NSString* kOpenFeintUserOptionClientApplicationId = @"OpenFeintSettingClientApplicationId";


@interface GreeOFUser : NSObject<NSCoding>
@property (nonatomic, retain) NSString* userId;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
@end

@implementation GreeOFUser
@synthesize userId;
- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self != nil) {
    userId = [[aDecoder decodeObjectForKey:@"resourceId"] retain];
  }  
  return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:userId forKey:@"resourceId"];
}
- (void)dealloc
{
  [userId release]; userId = nil;
  [super dealloc];
}
@end

@interface GreeDeviceIdentifier ()
+ (NSString*)urlendodeForBase64:(NSString*)aString;
+ (NSString*)secureUDID;
@end

@implementation GreeDeviceIdentifier

+ (NSString*)uniqueDeviceId
{
  NSString* udid = [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
  return (udid)?udid:@"";
}

+ (NSString*)macAddress 
{
	char *macAddressString = (char *)malloc(18);
	greeGetMacAddress(macAddressString, "en0");
	NSString *macAddress = [[[NSString alloc] initWithCString:macAddressString
    encoding:NSMacOSRomanStringEncoding] autorelease];
	free(macAddressString); macAddressString = NULL;
	return (macAddress)?[macAddress stringByReplacingOccurrencesOfString:@":" withString:@""]:@"";
}

+ (NSString*)secureUDID
{
  NSString* secureUDIDString = nil;
  Class klass = NSClassFromString(@"SecureUDID");
  if(klass) {
    if([klass respondsToSelector:@selector(UDIDForDomain:salt:)]) {
      secureUDIDString = [klass performSelector:@selector(UDIDForDomain:salt:) withObject:@"com.openfeint" withObject:@"dk25alfjdfki234aklsdf45hdhasfh"];
    }
    else if([klass respondsToSelector:@selector(UDIDForDomain:usingKey:)]) {
      secureUDIDString = [klass performSelector:@selector(UDIDForDomain:usingKey:) withObject:@"com.openfeint" withObject:@"dk25alfjdfki234aklsdf45hdhasfh"];
    }
  }
  return secureUDIDString;
}

+ (NSString*)ofAccessToken
{
  NSString *serverName = @"api.openfeint.com";
	NSString *securityDomain = @"api.openfeint.com";
  NSString *inName = @"oauth_token_access";
	NSMutableDictionary *findQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:	
    (id)kSecClassInternetPassword,kSecClass,
    securityDomain,kSecAttrSecurityDomain,
    serverName,kSecAttrServer,
    inName,kSecAttrAccount,
    kSecAttrAuthenticationTypeDefault,kSecAttrAuthenticationType,
    [NSNumber numberWithUnsignedLongLong:'oaut'],	kSecAttrType,
    nil
  ];												

	[findQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[findQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	
	NSData *keychainValueData = nil;
	int copyResultCode = SecItemCopyMatching((CFDictionaryRef)findQuery, (CFTypeRef *)&keychainValueData);
	
	NSString* foundValue = nil;
	if(copyResultCode == noErr)
  {
    foundValue = [[[NSString alloc] initWithBytes:[keychainValueData bytes] length:[keychainValueData length]  encoding:NSUTF8StringEncoding] autorelease];
		[keychainValueData release];
  }	
	return foundValue;
}

+ (NSString*)ofUserId
{
  NSData* encoded = [[NSUserDefaults standardUserDefaults] objectForKey:kOpenFeintUserOptionLocalUser];
  GreeOFUser* ofUser = nil;
  if (encoded) {
    NSKeyedUnarchiver* archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:encoded];
    [archiver setClass:[GreeOFUser class] forClassName:@"OFUser"];
    ofUser = (GreeOFUser*)[archiver decodeObjectForKey:@"root"];
    [archiver release];
  }
  return ofUser.userId;
}

+ (NSString*)ofApplicationId
{
  return [[NSUserDefaults standardUserDefaults] stringForKey:kOpenFeintUserOptionClientApplicationId];
}

+ (void)removeOfAccessToken
{
  if (![self ofAccessToken]) {
    return;
  }
  
  NSString *serverName = @"api.openfeint.com";
	NSString *securityDomain = @"api.openfeint.com";
  NSString *inName = @"oauth_token_access";
	NSMutableDictionary *findQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    (id)kSecClassInternetPassword,kSecClass,
                                    securityDomain,kSecAttrSecurityDomain,
                                    serverName,kSecAttrServer,
                                    inName,kSecAttrAccount,
                                    nil];
  SecItemDelete((CFDictionaryRef)findQuery);
}

+ (void)removeOfUserId
{
  if (![self ofUserId]) {
    return;
  }  
  
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOpenFeintUserOptionLocalUser];
}

+ (void)removeOfApplicationId
{
  if (![self ofApplicationId]) {
    return;
  }
  
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kOpenFeintUserOptionClientApplicationId];
}

+ (NSString*)deviceContextIdWithSecret:(NSString*)secret greeUUID:(NSString*)greeUUID
{
  //header
  NSDictionary* headerValue = [NSDictionary dictionaryWithObject:@"HS256" forKey:@"alg"];
  NSString* headerString = [headerValue greeJSONString];
	NSString* header = [[headerString dataUsingEncoding:NSUTF8StringEncoding] greeBase64EncodedString];
  header = [GreeDeviceIdentifier urlendodeForBase64:header];
  //payload
  NSMutableArray* keyArray = [NSMutableArray array];
  [keyArray addObject:greeUUID];
  NSString* secureUDIDString = [self secureUDID];
  if (secureUDIDString) {
    [keyArray addObject:secureUDIDString];
  }  
  NSMutableDictionary* payloadValue = [NSMutableDictionary dictionary];
  [payloadValue setValue:keyArray forKey:@"key"];
  NSString* ofAccessTokenString = [self ofAccessToken];
  if (ofAccessTokenString) {
    [payloadValue setValue:ofAccessTokenString forKey:@"okey"];
  }
  NSString* ofUserIdString = [self ofUserId];
  if (ofUserIdString) {
    [payloadValue setValue:ofUserIdString forKey:@"ouid"];
  }
  NSString* ofApplicationIdString = [self ofApplicationId];
  if (ofApplicationIdString) {
    [payloadValue setValue:ofApplicationIdString forKey:@"ogid"];
  }  
  NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSNumber *timeStamp = [NSNumber numberWithInt:(int)timeInterval];
  [payloadValue setValue:timeStamp forKey:@"timestamp"];
  
  NSString* payloadString = [payloadValue greeJSONString];  
  NSString* payload = [[payloadString dataUsingEncoding:NSUTF8StringEncoding] greeBase64EncodedString];
  payload = [GreeDeviceIdentifier urlendodeForBase64:payload];
  //signature
  NSString* msg = [NSString stringWithFormat:@"%@.%@", header, payload];
  NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
  NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, [secretData bytes], [secretData length], [msgData bytes], [msgData length], result);
  NSString* signature = [[NSData dataWithBytes:result length:CC_SHA256_DIGEST_LENGTH] greeBase64EncodedString];
  signature = [GreeDeviceIdentifier urlendodeForBase64:signature];
  
  return [NSString stringWithFormat:@"%@.%@.%@", header, payload, signature];
}

+ (NSString*)urlendodeForBase64:(NSString*)aString
{
	aString = [aString stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	aString = [aString stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
	aString = [aString stringByReplacingOccurrencesOfString:@"=" withString:@""];
  return aString;
}

@end

#define IFT_ETHER 6
// This code was based from http://stackoverflow.com/questions/677530/how-can-i-programmatically-get-the-mac-address-of-an-iphone/6104162#6104162
// We distribute under the CC-BY SA3.0.
char *greeGetMacAddress(char *macAddress, char *ifName)
{
	int success;
	struct ifaddrs *addrs;
	struct ifaddrs *cursor;
	const struct sockaddr_dl *dlAddr;
	const unsigned char *base;
	int i;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != 0) {
			dlAddr = (const struct sockaddr_dl *)cursor->ifa_addr;
			if (cursor->ifa_addr->sa_family == AF_LINK && dlAddr->sdl_type == IFT_ETHER && strcmp(ifName, cursor->ifa_name) == 0) {
				base = (const unsigned char*)&dlAddr->sdl_data[dlAddr->sdl_nlen];
				strcpy(macAddress, "");
				for (i = 0; i < dlAddr->sdl_alen; i++) {
					if (i != 0) {
						strcat(macAddress, ":");
					}
					char partialAddr[3];
					sprintf(partialAddr, "%02X", base[i]);
					strcat(macAddress, partialAddr);
				}
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}      
	return macAddress;
}
