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

#import "CustomScrollView.h"


@implementation CustomScrollView

- (UIViewController*)getControllerResponder
{
  UIViewController* controller = (UIViewController*)self.nextResponder;
  while (controller) {
    if ([controller isKindOfClass:[UIViewController class]] && self.superview == controller.view ) {
      break;
    }
    controller = (UIViewController*)controller.nextResponder;
  }
  return controller;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event 
{	
  // If not dragging, send event to this scroll view's view controller
  if (!self.dragging){
    [[self getControllerResponder] touchesEnded:touches withEvent:event];    
  }else {
    [super touchesEnded: touches withEvent: event];
  }
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}


@end
