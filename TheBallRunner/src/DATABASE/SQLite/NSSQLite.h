//
//  NSSQLite.h
//  HeathBook
//
//  Created by TLi Consulting 8/28/10.
//  Copyright 2010 Information Technologies Services Limited. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "sqlite3.h"


@interface NSSQLite : NSObject {
	NSInteger busyRetryTimeout;
	NSString *filePath;
	sqlite3 *_db;
}

@property (readwrite) NSInteger busyRetryTimeout;
@property (readonly) NSString *filePath;

+ (NSString *)createUuid;
+ (NSString *)version;

- (id)initWithFile:(NSString *)filePath;

- (BOOL)open:(NSString *)filePath;
- (void)close;

- (NSInteger)errorCode;
- (NSString *)errorMessage;

- (NSArray *)executeQuery:(NSString *)sql, ...;
- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)args;

- (BOOL)executeNonQuery:(NSString *)sql, ...;
- (BOOL)executeNonQuery:(NSString *)sql arguments:(NSArray *)args;

- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)beginTransaction;
- (BOOL)beginDeferredTransaction;

@end
