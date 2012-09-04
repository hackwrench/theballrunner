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

#import "GreeAnalyticsChunk.h"

@interface GreeAnalyticsChunk ()
@end

@implementation GreeAnalyticsChunk

@synthesize header =  _header;
@synthesize body = _body;

#pragma mark - Object Lifecycle

- (id)initWithHeader:(GreeAnalyticsHeader*)header body:(NSArray*)body {
  if ((self = [super init])) {
    _header = [header retain];
    _body = [body retain];
  }
  
  return self;
}

- (void)dealloc
{
  [_header release];
  [_body release];

  [super dealloc];
}

#pragma mark - GreeSerializable

- (id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  if((self = [super init])) {
    _header = [[serializer objectOfClass:[GreeAnalyticsHeader class] forKey:@"h"] retain];
    _body = [[serializer arrayOfSerializableObjectsWithClass:[GreeAnalyticsEvent class] forKey:@"b"] retain];
  }
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:_header forKey:@"h"];
  [serializer serializeArrayOfSerializableObjects:_body ofClass:[GreeAnalyticsEvent class] forKey:@"b"];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p, header:{ %@ }, bodyItemsCount:%d>",
    NSStringFromClass([self class]),
    self,
    [self.header description],
    [self.body count]];
}



@end
