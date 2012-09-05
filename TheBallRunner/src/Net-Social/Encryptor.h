//
//  Encryptor.h
//  UnderTheSea
//
//  Created by User on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Encryptor : NSObject

/*
 Obfuscate a source string by key
 @src : source string
 @key : used for obfuscation
 */
- (NSString*) obfuscate:(NSString*) src :(NSString*)key;

/*
 Encrypt the source string by a key
 Use a simple wrapping character
 @src : source string
 @key : key used to make encryption
 */
- (NSString*) encrypt:(NSString *)src :(NSString*)key;


/*
 Decrypt the encrypted-source string by key
 @src : encrypted source string
 @key : key used to make decryption
 */
- (NSString*) decrypt:(NSString *)src :(NSString*)key;

@end
