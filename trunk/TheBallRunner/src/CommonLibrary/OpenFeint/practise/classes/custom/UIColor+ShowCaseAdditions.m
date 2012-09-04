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

#import "UIColor+ShowCaseAdditions.h"

@implementation UIColor (ShowCaseAdditions)

+ (UIColor*)showcaseNavigationBarColor
{
  static UIColor* color = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    color = [[UIColor alloc] initWithRed:16.f/255.f green:158.f/255.f  blue:226.f/255.f  alpha:1];
    atexit_b(^{
      [color release]; color = nil;
    });
  });
  return color;
}

+ (UIColor*)showcaseDarkGrayColor
{
  static UIColor* color = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    color = [[UIColor alloc] initWithRed:92.f/255.f green:101.f/255.f  blue:109.f/255.f  alpha:1];
    atexit_b(^{
      [color release]; color = nil;
    });
  });
  return color;
}

+ (UIColor*)showcaseLightGrayColor
{
  static UIColor* color = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    color = [[UIColor alloc] initWithRed:167.f/255.f green:172.f/255.f  blue:188.f/255.f  alpha:1];
    atexit_b(^{
      [color release]; color = nil;
    });
  });
  return color;
}

+ (UIColor*)showcaseWhiteColor
{
  static UIColor* color = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    color = [[UIColor alloc] initWithRed:238.f/255.f green:238.f/255.f  blue:238.f/255.f  alpha:1];
    atexit_b(^{
      [color release]; color = nil;
    });
  });
  return color;
}

+ (UIColor*)showcaseBackgroundGrayColor
{
  static UIColor* color = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    color = [[UIColor alloc] initWithRed:139.f/255.f green:144.f/255.f  blue:147.f/255.f  alpha:1];
    atexit_b(^{
      [color release]; color = nil;
    });
  });
  return color;
}


@end
