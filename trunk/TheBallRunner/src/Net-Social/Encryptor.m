//
//  Encryptor.m
//  UnderTheSea
//
//  Created by User on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Encryptor.h"

@implementation Encryptor

//--------------------------------------------------
- (NSString*) obfuscate:(NSString*) src :(NSString*)key
{

    // Create data object from the string
    NSData *data = [src dataUsingEncoding:NSUTF8StringEncoding];
    
    // Get pointer to data to obfuscate
    char *dataPtr = (char *) [data bytes];
    
    // Get pointer to key data
    char *keyData = (char *) [[key dataUsingEncoding:NSUTF8StringEncoding] bytes];
    
    // Points to each char in sequence in the key
    char *keyPtr = keyData;
    int keyIndex = 0;
    
    // For each character in data, xor with current value in key
    for (int x = 0; x < [data length]; x++) 
    {
        // Replace current character in data with 
        // current character xor'd with current key value.
        // Bump each pointer to the next character
        *dataPtr = *dataPtr++ ^ *keyPtr++; 
        
        // If at end of key data, reset count and 
        // set key pointer back to start of key value
        if (++keyIndex == [key length])
            keyIndex = 0, keyPtr = keyData;
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

//--------------------------------------------------
- (NSString*) encrypt:(NSString *)src :(NSString*)key
{

    
    //use obfuscate to make encryption
    //prefix "###" as encrypted-mark to final obfuscated string
    
    //encrypt only if src dont have "###" prefix mark
    //otherwise return original src
    if ([src hasPrefix:@"###"]) return src; 
    
    NSString *obf=[self obfuscate:src :key];
    
    NSString *final=[NSString stringWithFormat:@"###%@",obf];    
    return final;
}

//--------------------------------------------------
- (NSString*) decrypt:(NSString *)src :(NSString*)key
{
    //decrypt only if src has "###" prefix mark
    //otherwise return original src    
    if(![src hasPrefix:@"###"]) return src;
    
    NSString *actual=[src substringFromIndex:3];
    
    NSString *final=[self obfuscate:actual :key];    
    return final;
}

@end
