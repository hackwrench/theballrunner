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


#import "GreeJSGetContactListCommand.h"
#import <AddressBook/AddressBook.h>
#import "JSONKit.h"

static NSString *const kGreeJSGetContactListParamsResultKey       = @"result";
static NSString *const kGreeJSGetContactListParamsCallbackKey     = @"callback";
static NSString *const kGreeJSGetContactListFirstNameKey          = @"firstName";
static NSString *const kGreeJSGetContactListLastNameKey           = @"lastName";
static NSString *const kGreeJSGetContactListHomePhoneNumberKey    = @"homePhoneNumber";
static NSString *const kGreeJSGetContactListMobilePhoneNumberKey  = @"mobilePhoneNumber";
static NSString *const kGreeJSGetContactListEmailKey              = @"emails";

@implementation GreeJSGetContactListCommand

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"get_contact_list";
}

- (void)execute:(NSDictionary *)params
{
  ABAddressBookRef addressBook = ABAddressBookCreate();
  NSArray *contactArray = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
  NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:[contactArray count]];
  
  for (int index = 0; index < [contactArray count]; index++) {
    
    ABRecordRef recordRef = (ABRecordRef)[contactArray objectAtIndex:index];
    NSMutableDictionary *contact = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    // First and last name.
    ABMultiValueRef firstName = ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
    if (firstName != nil) {
      [contact setObject:firstName forKey:kGreeJSGetContactListFirstNameKey];
      CFRelease(firstName);
    }
    
    ABMultiValueRef lastName = ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
    if (lastName != nil) {
      [contact setObject:lastName forKey:kGreeJSGetContactListLastNameKey];
      CFRelease(lastName);
    }
    
    
    // Email address (just take the first one available)
    ABMultiValueRef emailAddresses = ABRecordCopyValue(recordRef, kABPersonEmailProperty);
    if (emailAddresses != nil) {
      int numberOfAddresses = ABMultiValueGetCount(emailAddresses);
      if (numberOfAddresses > 0) {
        NSMutableArray *addresses = [NSMutableArray arrayWithCapacity:numberOfAddresses];
        for (int i = 0; i < numberOfAddresses; i++) {
          ABMultiValueRef address = ABMultiValueCopyValueAtIndex(emailAddresses, i);
          [addresses addObject:address];
          CFRelease(address);
        }
        [contact setObject:addresses
                    forKey:kGreeJSGetContactListEmailKey];
      }
      CFRelease(emailAddresses);
    }
    
    // Phone numbers.
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
    NSUInteger numberOfPhones = ABMultiValueGetCount(phoneNumbers);
    for (int phoneIndex = 0; phoneIndex < numberOfPhones; phoneIndex++) {
      CFStringRef phoneNumberLabel = ABMultiValueCopyLabelAtIndex(phoneNumbers, phoneIndex);
      if (phoneNumberLabel != nil) {
        NSString *phoneNumberValue = (NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, phoneIndex);
        
        if (CFStringCompare(phoneNumberLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {
          [contact setObject:phoneNumberValue forKey:kGreeJSGetContactListMobilePhoneNumberKey];
        } else if (CFStringCompare(phoneNumberLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
          [contact setObject:phoneNumberValue forKey:kGreeJSGetContactListHomePhoneNumberKey];
        }
        
        CFRelease(phoneNumberLabel);
        CFRelease(phoneNumberValue);
      }
    }
    CFRelease(phoneNumbers);
    
    [contacts addObject:contact];
    [contact release];
  }
  
  // Set params and perform callback.
  [params setValue:[contacts greeJSONString] forKey:kGreeJSGetContactListParamsResultKey];
  [[self.environment handler]
    callback:[params objectForKey:kGreeJSGetContactListParamsCallbackKey] 
    params:params];
  
  [contactArray release];
  CFRelease(addressBook);
}

@end
