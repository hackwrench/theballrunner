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


#import "GreeJSTakePhotoActionSheet.h"

@implementation GreeJSTakePhotoActionSheet
@synthesize tag                   = tag_;
@synthesize callbackFunction      = callbackFunction_;
@synthesize resetCallbackFunction = resetCallbackFunction_;

@synthesize takePhotoButtonIndex = _takePhotoButtonIndex;
@synthesize chooseFromAlbumButtonIndex = _chooseFromAlbumButtonIndex;
@synthesize removePhotoButtonIndex = _removePhotoButtonIndex;

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [callbackFunction_ release];
  [resetCallbackFunction_ release];
  callbackFunction_ = nil;
  resetCallbackFunction_ = nil;
  [super dealloc];
}

- (id)init
{
  self = [super init];
  if (self) {
    self.takePhotoButtonIndex = -1;
    self.chooseFromAlbumButtonIndex = -1;
    self.removePhotoButtonIndex = -1;
  }
  return self;
}

@end
