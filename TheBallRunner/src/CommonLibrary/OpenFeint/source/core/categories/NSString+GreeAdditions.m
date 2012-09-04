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

#import "NSString+GreeAdditions.h"
#import "NSData+GreeAdditions.h"
#import "GreeUtility.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (GreeAdditions)
- (NSString*)formatAsGreeVersion
{
  NSArray* pieces = [self componentsSeparatedByString:@"."];
  NSInteger firstValue = 0;
  NSInteger secondValue = 0;
  NSInteger thirdValue = 0;
  if(pieces.count > 0) {
    firstValue = [[pieces objectAtIndex:0] integerValue];
  }
  if(pieces.count > 1) {
    secondValue = [[pieces objectAtIndex:1] integerValue];
  }
  if(pieces.count > 2) {
    thirdValue = [[pieces objectAtIndex:2] integerValue];
  }
  return [NSString stringWithFormat:@"%04d.%02d.%02d", firstValue, secondValue, thirdValue];
}

- (NSDictionary*)greeHashWithNonceAndKeyPrefix:(NSString*)keyPrefix
{
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  CFStringRef nonce = CFUUIDCreateString(NULL, theUUID);
  [NSMakeCollectable(theUUID) autorelease];
  NSString* nonceObj = [(NSString*)nonce lowercaseString];
  
  NSString* secretKey = [keyPrefix stringByAppendingString:nonceObj];
  
  NSData *clearTextData = [self dataUsingEncoding:NSUTF8StringEncoding];
  NSString* hashString = [clearTextData greeHashWithKey:secretKey];

  CFRelease(nonce);

  return [NSDictionary dictionaryWithObjectsAndKeys:
          hashString, @"hash",
          nonceObj, @"nonce",
          nil];
}

- (NSString*)greeURLEncodedString
{
  NSString *anEncodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
  [anEncodedString autorelease];
  return anEncodedString;
}

- (NSString*)greeURLDecodedString
{
  NSString *aDecodedString = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
  [aDecodedString autorelease];
  return aDecodedString;
}

- (NSMutableDictionary*)greeDictionaryFromQueryString
{
  id pairs = [self componentsSeparatedByString:@"&"];
  id params = [NSMutableDictionary dictionaryWithCapacity:[pairs count]];
  for (NSString *aPair in pairs) {
    id keyAndValue = [aPair componentsSeparatedByString:@"="];
    if ([keyAndValue count] == 2) {
      [params setObject:[(NSString*)[keyAndValue objectAtIndex:1] greeURLDecodedString]
                 forKey:[(NSString*)[keyAndValue objectAtIndex:0] greeURLDecodedString]];
    }
  }
  return params;
}

+ (NSString*)greeDocumentsPathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+ (NSString*)greeTempPathForRelativePath:(NSString*)relativePath
{
  NSString* basePath = [NSTemporaryDirectory() stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+ (NSString*)greeCachePathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

+ (NSString*)greeLoggingPathForRelativePath:(NSString*)relativePath
{
  NSArray* folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString* basePath = [[folders objectAtIndex:0] stringByAppendingPathComponent:@"Logs"];
  basePath = [basePath stringByAppendingPathComponent:GreeSdkRelativePath()];
  return [basePath stringByAppendingPathComponent:relativePath];
}

- (NSData*)greeHexStringFormatInBinary 
{
  NSData* obj = [self dataUsingEncoding:NSASCIIStringEncoding];
  if (!obj) {
    return nil;
  }
  int length = [obj length];
  const char * hex = [obj bytes];  
  if ( length % 2) {
    return nil;
  }
  char *buffer = (char*)malloc((length / 2) + 1);
  
  char *p = buffer;
  const char *q = hex;
  
  int i = 0;
  while (i < length) {
    int n;
    int m = sscanf(q, "%02hhx%n", p, &n);
    if ( m != 1 ) {
      break;
    }
    q += n;
    i += n;
    ++p;
  }
  return [[[NSData alloc] initWithBytesNoCopy:buffer length:p - buffer freeWhenDone:YES] autorelease];
}

- (NSString*)greeStringByReplacingHtmlLocalizedStringWithKey:(NSString*)key withString:(NSString*)localizedString
{
  NSString* replaced = nil;
  
  NSRange localizedRange = [self rangeOfString:[NSString stringWithFormat:@"<!-- localized:%@ -->", key]];
  if (localizedRange.location != NSNotFound) {
    NSUInteger newStartLocation = localizedRange.location + localizedRange.length;
    NSRange closingTagRange = [self rangeOfString:@"<!-- localized -->" options:0x0 range:NSMakeRange(newStartLocation, [self length] - newStartLocation)];
    if (closingTagRange.location != NSNotFound) {
      NSUInteger replacementLength = (closingTagRange.location + closingTagRange.length) - localizedRange.location;
      replaced = [self stringByReplacingCharactersInRange:NSMakeRange(localizedRange.location, replacementLength) withString:localizedString];
    }
  }
  
  if (!replaced) {
    // we can't end up with nothing
    replaced = [[self copy] autorelease];
  }
  
  return replaced;
}

@end
