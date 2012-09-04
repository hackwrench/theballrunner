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

#import "GreeLogger.h"
#import "NSString+GreeAdditions.h"

@interface GreeLogger ()
@property (nonatomic, retain) NSFileHandle* logHandle;
@end

@implementation GreeLogger

@synthesize level = _level;
@synthesize includeFileLineInfo = _includeFileLineInfo;
@synthesize logToFile = _logToFile;
@synthesize logHandle = _logHandle;

#pragma mark - Object Lifecycle

- (id)init
{
  self = [super init];
  if (self != nil) {
    _level = GreeLogLevelInfo;
    _includeFileLineInfo = YES;    
  }
  
  return self;
}

- (void)dealloc
{
  [_logHandle release];
  [super dealloc];
}

#pragma mark - Public Interface

- (BOOL)log:(NSString*)message level:(NSInteger)level fromFile:(char const*)file atLine:(int)line, ...
{
  BOOL shouldLog = self.level >= level;
  if (shouldLog) {
    NSMutableString* prefix = [[NSMutableString alloc] initWithCapacity:64];
    [prefix appendString:@"[Gree]"];
    
    if (self.includeFileLineInfo) {
      NSString* fileString = [[NSString alloc] initWithUTF8String:file];
      [prefix appendFormat:@"[%@:%d] ", [fileString lastPathComponent], line];
      [fileString release];
    }
    
    va_list args;
    va_start(args, line);
    NSString* formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    
    NSString* finalString = [[NSString alloc] initWithFormat:@"%@ %@", prefix, formattedMessage];
    NSLog(@"%@", finalString);
    if(self.logHandle) {
      NSString* withNewline = [finalString stringByAppendingString:@"\n"];
      [self.logHandle writeData:[withNewline dataUsingEncoding:NSUTF8StringEncoding]];
    }
                               
    [finalString release];                           
    [formattedMessage release];
    [prefix release];
  }
  
  return shouldLog;
}

- (BOOL)logToFile
{
  return _logToFile;
}

- (void)setLogToFile:(BOOL)logToFile
{
  _logToFile = logToFile;
  if(logToFile && !self.logHandle) {
    NSString* fileName = [NSString stringWithFormat:@"Log %@", [NSDate date]];
    fileName = [fileName stringByReplacingOccurrencesOfString:@":" withString:@"."];
    NSString*filePath = [NSString greeLoggingPathForRelativePath:fileName];
    [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.logHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
  } else if (!logToFile && self.logHandle) {
    self.logHandle = NULL;
  }
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:
    @"<%@:%p, level:%d, includeFileLineInfo:%@>", 
    NSStringFromClass([self class]), 
    self,
    self.level,
    self.includeFileLineInfo ? @"YES" : @"NO"];
}

#pragma mark - Internal Methods

@end
