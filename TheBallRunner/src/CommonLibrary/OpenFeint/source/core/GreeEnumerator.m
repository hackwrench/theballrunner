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

#import "GreeEnumerator+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeError+Internal.h"
#import "AFHTTPRequestOperation.h"
#import "GreeAuthorization.h"

@interface GreeEnumeratorBase ()
@property (nonatomic, readwrite, assign) BOOL hasNextPage;
- (void)loadFromIndex:(NSInteger)startIndex pageSize:(NSInteger)count block:(GreeEnumeratorResponseBlock) block;
@end

@implementation GreeEnumeratorBase
@synthesize startIndex = _startIndex;
@synthesize enumeratorStartIndex = _enumeratorStartIndex;
@synthesize pageSize = _pageSize;
@synthesize hasNextPage = _hasNextPage;
@synthesize guid = _guid;

#pragma mark - Object Lifecycle
- (id)initWithStartIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize
{
  self = [super init];
  if(self) {
    _startIndex = startIndex;
    _enumeratorStartIndex = startIndex;
    _pageSize = pageSize;
    _guid = @"me";
  }
  return self;
}

- (void)dealloc
{
  [_guid release];
  [super dealloc];
}

#pragma mark - Public Interface
- (void)loadNext:(GreeEnumeratorResponseBlock)block
{
  [self loadFromIndex:self.startIndex pageSize:self.pageSize block:block];
}

- (void)loadPrevious:(GreeEnumeratorResponseBlock)block
{
  NSInteger newStart = self.startIndex - self.pageSize * 2;
  if(newStart < self.enumeratorStartIndex) { 
    newStart = self.enumeratorStartIndex;
  }
  [self loadFromIndex:newStart pageSize:self.pageSize block:block];
}

- (BOOL)canLoadPrevious
{
  if (self.startIndex <= self.enumeratorStartIndex + self.pageSize) {
    return NO;
  }else{
    return YES;
  }
}

- (BOOL)canLoadNext
{
  return self.hasNextPage;
}


#pragma mark - Advanced enumerator properties
- (NSString*)guid
{
  if(!_guid) {
    return @"me";
  }
  return _guid;
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p startIndex:%d pageSize:%d>", NSStringFromClass([self class]), self, self.startIndex, self.pageSize];
}

#pragma mark - Internal Methods
- (NSString*)httpRequestPath
{
  NSAssert(0, @"You must override httpRequestPath in a GreeEnumerator");
  return nil;
}

- (NSArray*)convertData:(NSArray*)input
{
  NSAssert(0, @"You must override convertData in a GreeEnumerator");
  return nil;
}

//this is to allow a subclass to define other error handling capabilities
//by default, it calls the master error handler
- (NSError*)convertError:(NSError*)input
{
  return [GreeError convertToGreeError:input];
}

- (void)updateParams:(NSMutableDictionary *)params
{  
}

- (NSString*)retryService
{
  return nil;
}

- (void)loadFromIndex:(NSInteger)startIndex pageSize:(NSInteger)pageSize block:(GreeEnumeratorResponseBlock) block
{
  if(!block) {
    return;
  }
  
  if (![[GreeAuthorization sharedInstance] isAuthorized]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeNotAuthorized]);
    });
    return;
  }
  
  //make the http request, this will return an array and error message 
  if([GreePlatform sharedInstance].localUser == nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      block(nil, [GreeError localizedGreeErrorWithCode:GreeErrorCodeUserRequired]);
    });
    return;
  }
    
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", startIndex] forKey:@"startIndex"];
  if(pageSize > 0) {
    [params setObject:[NSString stringWithFormat:@"%d", pageSize] forKey:@"count"];
  }
  [self updateParams:params];
  
  void(^successBlock)(GreeAFHTTPRequestOperation * operation, id responseObject)  = ^(GreeAFHTTPRequestOperation * operation, id responseObject){
    NSArray* returnArray = nil;
    NSError* returnError = nil;
    if (operation.response.statusCode == 404) {
      responseObject = [NSDictionary  dictionaryWithObjectsAndKeys:
                        [NSArray array], @"entry",
                        [NSNumber numberWithInt:0], @"itemsPerPage", 
                        [NSNumber numberWithInt:0], @"totalResults",
                        [NSNumber numberWithBool:NO], @"hasNext", 
                        nil];
    }
    
    if(![responseObject isKindOfClass:[NSDictionary class]]) {
      returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
    } else {
      returnArray = [responseObject objectForKey:@"entry"];
      if(![returnArray isKindOfClass:[NSArray class]]) {
        returnError = [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer];
        returnArray = nil;
      }
      else {
        returnArray = [self convertData:returnArray];
        if(returnArray.count == 0) {
          returnArray = nil;
        }
        
        if(self.pageSize == 0){
          self.pageSize = [[responseObject objectForKey:@"itemsPerPage"] intValue];
        }
        
        self.startIndex = startIndex + self.pageSize;
        
        if ([responseObject objectForKey:@"hasNext"] != nil) {
          self.hasNextPage = [[responseObject objectForKey:@"hasNext"] boolValue];
        }else {
          int totalResult = [[responseObject objectForKey:@"totalResults"] intValue];
          int lastResultIndex = self.enumeratorStartIndex + totalResult - 1;
          if (self.startIndex <= lastResultIndex) {
            self.hasNextPage = YES;
          }else{
            self.hasNextPage = NO;
          }
        }
        
      }
    }                            
    block(returnArray, returnError);
  };
  
  void(^failureBlock)(GreeAFHTTPRequestOperation* operation, id responseObject) = ^(GreeAFHTTPRequestOperation* operation, id error) {
    block(nil, [self convertError:error]); 
  };
  
  
  
  [[GreePlatform sharedInstance].httpClient getPath:[self httpRequestPath]
                          parameters:params
                          success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
                            successBlock(operation, responseObject);
                          }
                          failure:^(GreeAFHTTPRequestOperation *operation, NSError* error) {
                            failureBlock(operation, error);
                          }
   ];
}

@end
