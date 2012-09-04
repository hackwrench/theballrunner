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

#import "GreeJSUIImage+TakePhoto.h"
#include "Base64Transcoder.h"

@implementation UIImage (GreeJSUIImageTakePhotoAdditions)

+ (UIImage *)greeImageWithBase64:(NSString *)base64
{
  const char *data = [base64 UTF8String];
  size_t length = [base64 length];
  int decodedSize = GreeEstimateBase64DecodedDataSize(length);
  char *decodeBuffer = malloc(sizeof(char) * decodedSize);
  size_t theResultLength = decodedSize;

  bool result = GreeBase64DecodeData(data, length, decodeBuffer, &theResultLength);
  if (result)
  {
    NSData *theData = [NSData dataWithBytes:decodeBuffer length:theResultLength];
    free(decodeBuffer);
    UIImage *image = [UIImage imageWithData:theData];
    return image;
  }
  free(decodeBuffer);
  return nil;
}

@end
