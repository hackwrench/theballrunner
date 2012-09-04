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

#import "GreeSerializer.h"
#import "GreeSerializable.h"
#import "NSDateFormatter+GreeAdditions.h"

@interface GreeSerializer ()
@property (nonatomic, retain) NSMutableDictionary* root;
@property (nonatomic, assign) NSMutableDictionary* currentContainer;
- (BOOL)objectIsSerialized:(id)object;
- (NSArray*)deserializeArrayOfSerializableObjects:(NSArray*)array withClass:(Class)klass;
@end

@implementation GreeSerializer

@synthesize deserialzeIntoMutableContainers = _deserialzeIntoMutableContainers;
@synthesize root = _root;
@synthesize currentContainer = _currentContainer;

#pragma mark - Object Lifecycle

+ (id)serializer
{
  return [[[self alloc] initWithSerializedDictionary:nil] autorelease];
}

+ (id)deserializerWithDictionary:(NSDictionary*)dictionary
{
  return [[[self alloc] initWithSerializedDictionary:dictionary] autorelease];
}

- (id)initWithSerializedDictionary:(NSDictionary*)dictionary
{
  self = [super init];
  if (self != nil) {
    if (dictionary == nil) {
      _root = [[NSMutableDictionary alloc] initWithCapacity:4];
    } else {
      _root = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    _currentContainer = _root;
  }
  
  return self;
}

- (void)dealloc
{
  [_root release];
  [super dealloc];
}

#pragma mark - NSObject Overrides

- (NSString*)description;
{
  return [NSString stringWithFormat:@"<%@:%p, root:%@>", NSStringFromClass([self class]), self, self.root];
}

#pragma mark - Public Interface

- (NSDictionary*)rootDictionary
{
  return [NSDictionary dictionaryWithDictionary:_root];
}

+ (NSArray*)deserializeArray:(NSArray*)array withClass:(Class)klass
{
  NSArray* deserialized = nil;
  if ([array count] > 0 && klass != nil) {
    GreeSerializer* serializer = [[[GreeSerializer alloc] initWithSerializedDictionary:[NSDictionary dictionaryWithObject:array forKey:@"array"]] autorelease];
    deserialized = [serializer arrayOfSerializableObjectsWithClass:klass forKey:@"array"];
  }
  
  return deserialized;
}

#pragma mark Deserialization

- (id)objectForKey:(NSString*)key
{
  id object = [_currentContainer objectForKey:key];
  
  if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
    object = _deserialzeIntoMutableContainers ? [[object mutableCopy] autorelease] : [[object copy] autorelease];
  }

  return object;
}

- (id)objectOfClass:(Class)klass forKey:(NSString*)key
{
  NSAssert([klass conformsToProtocol:@protocol(GreeSerializable)], @"Attempting to deserialize a %@ which does NOT adopt GreeSerializable!", klass);

  NSMutableDictionary* previousContainer = _currentContainer;
  _currentContainer = [_currentContainer objectForKey:key];
  
  id object = nil;
  if (_currentContainer != nil) {
    object = [[klass alloc] initWithGreeSerializer:self];
  }

  _currentContainer = previousContainer;
  return [object autorelease];
}

- (NSDate*)UTCDateForKey:(NSString*)key
{
  NSString* dateString = [_currentContainer objectForKey:key];
  return [[NSDateFormatter greeUTCDateFormatter] dateFromString:dateString];
}

- (NSDate*)dateForKey:(NSString*)key
{
  NSString* dateString = [_currentContainer objectForKey:key];
  return [[NSDateFormatter greeStandardDateFormatter] dateFromString:dateString];
}

- (NSInteger)integerForKey:(NSString*)key
{
  return [[_currentContainer objectForKey:key] integerValue];
}

- (int64_t)int64ForKey:(NSString*)key
{
  return [[_currentContainer objectForKey:key] longLongValue];
}

- (double)doubleForKey:(NSString*)key
{
  return [[_currentContainer objectForKey:key] doubleValue];
}

- (BOOL)boolForKey:(NSString*)key
{
  return [[_currentContainer objectForKey:key] boolValue];
}

- (NSURL*)urlForKey:(NSString*)key
{
  NSURL* url = nil;
  id obj = [_currentContainer objectForKey:key];
  if ([obj isKindOfClass:[NSString class]]) {
    url = [NSURL URLWithString:obj];
  }
  return url;
}

- (NSArray*)arrayOfSerializableObjectsWithClass:(Class)klass forKey:(NSString*)key
{
  NSArray* serializedArray = [_currentContainer objectForKey:key];
  return [self deserializeArrayOfSerializableObjects:serializedArray withClass:klass];
}

- (NSDictionary*)dictionaryOfSerializableObjectsWithClass:(Class)klass forKey:(NSString*)key
{
  NSDictionary* serializedDictionary = [_currentContainer objectForKey:key];
  NSMutableDictionary* deserializedDictionary = [[NSMutableDictionary alloc] initWithCapacity:[serializedDictionary count]];
  
  for (id key in serializedDictionary) {
    NSAssert([key isKindOfClass:[NSString class]], @"Dictionary keys must be of type NSString!");
    
    id deserialized = nil;
    id obj = [serializedDictionary objectForKey:key];

    if ([obj isKindOfClass:[NSArray class]]) {
      deserialized = [[self deserializeArrayOfSerializableObjects:obj withClass:klass] retain];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
      NSMutableDictionary* previousContainer = _currentContainer;
      _currentContainer = obj;
      deserialized = [[klass alloc] initWithGreeSerializer:self];
      _currentContainer = previousContainer;
    } else {
      NSAssert(NO, @"Attempt to deserialize an NSDictionary with an incompatible object type! Expected: NSArray or NSDictionary; Received: %@", [obj class]);
    }
    
    if (deserialized != nil) {
      [deserializedDictionary setObject:deserialized forKey:key];
      [deserialized release];
    }
  }
  
  if (_deserialzeIntoMutableContainers) {
    return [deserializedDictionary autorelease];
  } else {
    NSDictionary* immutable = [NSDictionary dictionaryWithDictionary:deserializedDictionary];
    [deserializedDictionary release];
    return immutable;
  }
}

#pragma mark Serialization

- (void)serializeObject:(id)objectToSerialize forKey:(NSString*)key
{
  if ([objectToSerialize respondsToSelector:@selector(serializeWithGreeSerializer:)]) {
    NSMutableDictionary* previousContainer = _currentContainer;
    _currentContainer = [[NSMutableDictionary alloc] init];
    [objectToSerialize serializeWithGreeSerializer:self];
    [previousContainer setObject:_currentContainer forKey:key];
    [_currentContainer release];
    _currentContainer = previousContainer;
  } else if ([objectToSerialize isKindOfClass:[NSArray class]]) {
    NSAssert([self objectIsSerialized:objectToSerialize], @"Array members must all be supported types for direct serialization!");
    [_currentContainer setObject:objectToSerialize forKey:key];
  } else if ([objectToSerialize isKindOfClass:[NSDictionary class]]) {
    NSAssert([self objectIsSerialized:objectToSerialize], @"Dictionary objects must all be supported types, and keys must be NSStrings for direct serialization!");
    [_currentContainer setObject:objectToSerialize forKey:key];
  } else if ([objectToSerialize isKindOfClass:[NSNumber class]] ||
    [objectToSerialize isKindOfClass:[NSString class]] ||
    [objectToSerialize isKindOfClass:[NSNull class]]) {
    [_currentContainer setObject:objectToSerialize forKey:key];
  } else if (objectToSerialize != nil) {
    NSAssert(NO, @"Attempting to serialize unknown class: %@", [objectToSerialize class]);
  }
}

- (void)serializeDate:(NSDate*)dateToSerialize forKey:(NSString*)key
{
  [self serializeObject:[[NSDateFormatter greeStandardDateFormatter] stringFromDate:dateToSerialize] forKey:key];
}

- (void)serializeUTCDate:(NSDate*)dateToSerialize forKey:(NSString*)key
{
  [self serializeObject:[[NSDateFormatter greeUTCDateFormatter] stringFromDate:dateToSerialize] forKey:key];
}

- (void)serializeInteger:(NSInteger)integerToSerialize forKey:(NSString*)key
{
  [self serializeObject:[NSNumber numberWithInteger:integerToSerialize] forKey:key];
}

- (void)serializeInt64:(int64_t)int64ToSerialize forKey:(NSString*)key
{
  [self serializeObject:[NSNumber numberWithLongLong:int64ToSerialize] forKey:key];
}

- (void)serializeDouble:(double)doubleToSerialize forKey:(NSString*)key
{
  [self serializeObject:[NSNumber numberWithDouble:doubleToSerialize] forKey:key];
}

- (void)serializeBool:(BOOL)boolToSerialize forKey:(NSString*)key
{
  [self serializeObject:[NSNumber numberWithBool:boolToSerialize] forKey:key];
}

- (void)serializeUrl:(NSURL*)urlToSerialize forKey:(NSString*)key
{
  [self serializeObject:[urlToSerialize absoluteString] forKey:key];
}

- (void)serializeArrayOfSerializableObjects:(NSArray*)arrayToSerialize ofClass:(Class)klass forKey:(NSString*)key
{
  NSAssert([klass conformsToProtocol:@protocol(GreeSerializable)], @"Class type must conform to GreeSerializable");
  
  NSMutableArray* serializedArray = [[NSMutableArray alloc] initWithCapacity:[arrayToSerialize count]];
  
  for (id obj in arrayToSerialize) {
    NSMutableDictionary* previousContainer = _currentContainer;
    _currentContainer = [[NSMutableDictionary alloc] init];

    if ([obj isKindOfClass:[NSArray class]]) {
      [self serializeArrayOfSerializableObjects:obj ofClass:klass forKey:@"internalArray"];
      [serializedArray addObject:[_currentContainer objectForKey:@"internalArray"]];
    } else if ([obj isMemberOfClass:klass]) {
      [obj serializeWithGreeSerializer:self];
      [serializedArray addObject:_currentContainer];
    } else {
      NSAssert(NO, @"Attempt to serialize an NSArray with an incompatible object type! Expected: NSArray or %@; Received: %@", klass, [obj class]);
    }

    [_currentContainer release];
    _currentContainer = previousContainer;
  }
  
  NSArray* immutable = [NSArray arrayWithArray:serializedArray];
  [serializedArray release];
  
  [_currentContainer setObject:immutable forKey:key];
}

- (void)serializeDictionaryOfSerializableObjects:(NSDictionary*)dictionaryToSerialize ofClass:(Class)klass forKey:(NSString*)key
{
  NSAssert([klass conformsToProtocol:@protocol(GreeSerializable)], @"Class type must conform to GreeSerializable");

  NSMutableDictionary* serializedDictionary = [[NSMutableDictionary alloc] initWithCapacity:[dictionaryToSerialize count]];
  
  for (NSString* key in dictionaryToSerialize) {
    NSAssert([key isKindOfClass:[NSString class]], @"Dictionary keys must be of type NSString!");

    NSMutableDictionary* previousContainer = _currentContainer;
    _currentContainer = [[NSMutableDictionary alloc] init];

    id obj = [dictionaryToSerialize objectForKey:key];
    if ([obj isKindOfClass:[NSArray class]]) {
      [self serializeArrayOfSerializableObjects:obj ofClass:(Class)klass forKey:@"internalArray"];
      [serializedDictionary setObject:[_currentContainer objectForKey:@"internalArray"] forKey:key];
    } else if ([obj isMemberOfClass:klass]) {
      [obj serializeWithGreeSerializer:self];
      [serializedDictionary setObject:_currentContainer forKey:key];
    } else {
      NSAssert(NO, @"Attempt to serialize an NSDictionary with an incompatible object type!"
        @"Expected: NSArray or %@; Received: %@", klass, [obj class]);
    }

    [_currentContainer release];
    _currentContainer = previousContainer;
  }
  
  NSDictionary* immutable = [NSDictionary dictionaryWithDictionary:serializedDictionary];
  [serializedDictionary release];
  
  [_currentContainer setObject:immutable forKey:key];
}

#pragma mark - Internal Methods

- (BOOL)objectIsSerialized:(id)object
{
  __block BOOL valid = YES;

  if ([object isKindOfClass:[NSArray class]]) {
    [object enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
      valid = valid && [self objectIsSerialized:obj];
      *stop = !valid;
    }];
  } else if ([object isKindOfClass:[NSDictionary class]]) {
    [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
      valid = valid && [key isKindOfClass:[NSString class]] && [self objectIsSerialized:obj];
      *stop = !valid;
    }];
  } else if ([object isKindOfClass:[NSNumber class]] ||
    [object isKindOfClass:[NSString class]] ||
    [object isKindOfClass:[NSNull class]]) {
    valid = YES;
  } else {
    valid = NO;
  }
  
  return valid;
}

- (NSArray*)deserializeArrayOfSerializableObjects:(NSArray*)array withClass:(Class)klass
{
  NSMutableArray* deserializedArray = [[NSMutableArray alloc] initWithCapacity:[array count]];

  for (id obj in array) {
    NSMutableDictionary* previousContainer = _currentContainer;
    _currentContainer = obj;
    
    id deserialized = nil;
    
    if ([obj isKindOfClass:[NSArray class]]) {
      deserialized = [[self deserializeArrayOfSerializableObjects:obj withClass:klass] retain];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
      deserialized = [[klass alloc] initWithGreeSerializer:self];
    } else {
      NSAssert(NO, @"Attempt to deserialize an NSArray with an incompatible object type! Expected: NSArray or NSDictionary; Received: %@", [obj class]);
    }

    if (deserialized != nil) {
      [deserializedArray addObject:deserialized];
      [deserialized release];
    }
    
    _currentContainer = previousContainer;
  }
  
  if (_deserialzeIntoMutableContainers) {
    return [deserializedArray autorelease];
  } else {
    NSArray* immutable = [NSArray arrayWithArray:deserializedArray];
    [deserializedArray release];
    return immutable;
  }
}

@end
