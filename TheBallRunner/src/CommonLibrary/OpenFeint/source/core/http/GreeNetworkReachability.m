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

#import "GreeNetworkReachability.h"

#import <SystemConfiguration/SystemConfiguration.h>

@interface GreeNetworkReachability ()
@property (nonatomic, assign) GreeNetworkReachabilityStatus status;
@property (nonatomic, assign, readonly) SCNetworkReachabilityRef reachability;
@property (nonatomic, retain, readonly) NSMutableSet* observers;
@property (nonatomic, assign, getter=areObserversLocked) BOOL observersLocked;
- (void)_setReachabilityFromFlags:(SCNetworkReachabilityFlags)flags;
@end

static void GreeNetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
  GreeNetworkReachability* reachabilityInstance = (GreeNetworkReachability*)info;
  [reachabilityInstance _setReachabilityFromFlags:flags];
}

NSString* NSStringFromGreeNetworkReachabilityStatus(GreeNetworkReachabilityStatus status)
{
  NSString* statusAsString = nil;
  
  switch (status) {
  case GreeNetworkReachabilityUnknown:
    statusAsString = @"Unknown";
    break;
    
  case GreeNetworkReachabilityConnectedViaWiFi:
    statusAsString = @"Connected via WiFi";
    break;
  
  case GreeNetworkReachabilityConnectedViaCarrier:
    statusAsString = @"Connected via Carrier Network";
    break;

  case GreeNetworkReachabilityNotConnected:
    statusAsString = @"Not Connected";
    break;
    
  default:
    NSCAssert(NO, @"Unhandled network reachability status!");
  };
  
  return statusAsString;
}

BOOL GreeNetworkReachabilityStatusIsConnected(GreeNetworkReachabilityStatus status)
{
  return 
    status == GreeNetworkReachabilityConnectedViaCarrier || 
    status == GreeNetworkReachabilityConnectedViaWiFi;
}

@implementation GreeNetworkReachability

@synthesize host = _host;
@synthesize status = _status;
@synthesize reachability = _reachability;
@synthesize observers = _observers;
@synthesize observersLocked = _observersLocked;

#pragma mark - Object Lifecycle

- (id)initWithHost:(NSString*)host
{
	self = [super init];
	if (self != nil) {
    _host = [[[NSURL URLWithString:host] host] retain];
    _status = GreeNetworkReachabilityUnknown;
		_observers = [[NSMutableSet alloc] initWithCapacity:1];

    if (_host != nil) {
      SCNetworkReachabilityContext context = { 
        0, (void*)self, NULL, NULL, NULL 
      };
      _reachability = SCNetworkReachabilityCreateWithName(NULL, [_host UTF8String]);
      SCNetworkReachabilitySetCallback(_reachability, GreeNetworkReachabilityCallback, &context);
      SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    } else {
      [self release];
      self = nil;
    }
	}
	
	return self;
}

- (void)dealloc
{
  [_host release];
  if (_reachability != NULL) {
    SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    CFRelease(_reachability);
  }
  [_observers release];

  [super dealloc];
}

#pragma mark - Public Interface

- (id)addObserverBlock:(void(^)(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current))observer
{
  NSAssert(![self areObserversLocked], @"GreeNetworkReachability cannot mutate observers while they are being iterated.");
  id blockHandle = Block_copy(observer);
  [self.observers addObject:blockHandle];
  return blockHandle;
}

- (void)removeObserverBlock:(id)handle
{
  NSAssert(![self areObserversLocked], @"GreeNetworkReachability cannot mutate observers while they are being iterated.");
  [self.observers removeObject:handle];
}

- (BOOL)isConnectedToInternet
{
  return GreeNetworkReachabilityStatusIsConnected(self.status);
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:
    @"<%@:%p, host:%@, status:%@>", 
    NSStringFromClass([self class]), 
    self,
    self.host,
    NSStringFromGreeNetworkReachabilityStatus(self.status)];
}

#pragma mark - Internal Methods

- (void)_setReachabilityFromFlags:(SCNetworkReachabilityFlags)flags
{
	GreeNetworkReachabilityStatus previous = self.status;
  GreeNetworkReachabilityStatus current = GreeNetworkReachabilityConnectedViaWiFi;

	BOOL connectionRequired = (flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired;
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
    current = GreeNetworkReachabilityConnectedViaCarrier;
		connectionRequired = NO;
	}
		
	BOOL reachable = ((flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable) && !connectionRequired;
	if (!reachable) {
    current = GreeNetworkReachabilityNotConnected;
	}
  
  self.status = current;
  self.observersLocked = YES;
  
  for (GreeNetworkReachabilityChangedBlock block in self.observers) {
    block(previous, current);
  }
  
  self.observersLocked = NO;
}

@end
