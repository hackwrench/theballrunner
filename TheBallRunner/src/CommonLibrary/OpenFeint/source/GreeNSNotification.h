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

/**
 * @file
 * @brief NSNotifications that can be sent by the GreePlatform subsystems.
 */


#import <Foundation/Foundation.h>


/**
 * @brief Notification sent when Popup/NotificationBoard/Dashboard closed.
 */
extern NSString* const GreeNSNotificationKeyDidCloseNotification;

/**
 * @brief Notification sent when the localUser property in GreePlatform has been updated.
 */
extern NSString* const GreeNSNotificationKeyDidUpdateLocalUserNotification;
