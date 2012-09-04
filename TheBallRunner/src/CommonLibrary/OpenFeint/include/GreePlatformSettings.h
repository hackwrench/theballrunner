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
 * @file GreePlatformSettings.h
 * GreePlatform initialization settings. These constants should be used to build
 * the settings dictionary for [GreePlatform initializeWithProductKey...].
 */

#import <Foundation/Foundation.h>

/**
 * @brief Set development mode
 * 
 * Use this setting to toggle between Production or Sandbox development modes. This controls, among other
 * things, which server you will connect to.
 *
 * @see GreeDevelopmentModeProduction
 * @see GreeDevelopmentModeSandbox
 */
extern NSString* const GreeSettingDevelopmentMode;
/**
 * Specify this value for the setting GreeSettingDevelopmentMode to connect to the production environment.
 * The production environment should be used for your Distribution and AdHoc builds that will be deployed
 * to users.
 *
 * @see GreeSettingDevelopmentMode
 */
extern NSString* const GreeDevelopmentModeProduction;
/**
 * Specify this value for the setting GreeSettingDevelopmentMode to connect to the sandbox environment.
 * You can use the sandbox environment during development to test changes without affecting your live
 * users on the production environment.
 *
 * @see GreeSettingDevelopmentMode
 */
extern NSString* const GreeDevelopmentModeSandbox;

/**
 * Specify the orientation that Gree should use. Your application, if it supports multiple
 * orientations, is expected to update GreePlatform via +[GreePlatform setInterfaceOrientation:] when
 * orientation changes occur. All views (dashboard, popups, notifications) will use this.
 * Values are expected to be [NSNumber numberWithInteger:(UIInterfaceOrientation)].
 *
 * @note Default value is UIInterfaceOrientationPortrait
 */
extern NSString* const GreeSettingInterfaceOrientation;

/**
 * Specify the positioning for Gree notification views.
 * @note Default is GreeNotificationDisplayTopPosition
 * @see GreeNotificationDisplayPosition
 */
extern NSString* const GreeSettingNotificationPosition;

/**
 * Specify whether or not to show notifications.
 * @note Default is YES
 */
extern NSString* const GreeSettingNotificationEnabled;

/**
 * Specify the positioning for Gree widget view.
 * @note Default is GreeWidgetPositionBottomLeft
 * @see GreeWidgetPosition
 */
extern NSString* const GreeSettingWidgetPosition;

/**
 * Specify if you want Gree widget to be expandable or not
 * @note Default is YES
 */
extern NSString* const GreeSettingWidgetExpandable;

/**
 * @brief Define mappings for achievements from GameCenter to Gree.
 *
 * When this setting is enabled GreePlatform will submit achievements to GameCenter at the same time
 * they are unlocked via the GreeAchievement APIs. 
 * 
 * Expected value is an NSDictionary where the keys are Gree achievement identifiers (NSString)
 * and the objects are GameCenter acheivement identifiers (NSString).
 */
extern NSString* const GreeSettingGameCenterAchievementMapping;

/**
 * @brief Define mappings for leaderboards from GameCenter to Gree.
 *
 * When this setting is enabled GreePlatform will submit scores to GameCenter at the same time they 
 * are submitted via the GreeScore APIs.
 * 
 * Expected value is an NSDictionary where the keys are Gree leaderboard identifiers (NSString)
 * and the objects are GameCenter leaderboard categories (NSString).
 */
extern NSString* const GreeSettingGameCenterLeaderboardMapping;

/**
 * @brief Toggle logging
 *
 * GreePlatform logging is enabled by default. You can disable all logging by providing this setting
 * with a value of [NSNumber numberWithBool:NO].
 */ 
extern NSString* const GreeSettingEnableLogging;

/**
 * @brief Toggle writing log to a file.
 *
 * Logging to file is disabled by default. You can enable it with a value of [NSNumber numberWithBool:NO].
 * Logs will be written to Library/Logs/.
 */ 
extern NSString* const GreeSettingWriteLogToFile;

/**
 * Pre-defined logging thresholds, from least-verbose to most-verbose.
 */
typedef enum {
/**
 * GreeLogLevelPublic will show only the most essential log messages.
 */
  GreeLogLevelPublic = 0,
/**
 * GreeLogLevelWarn will show public messages as well as those designed 
 * to warn you of dangerous behavior.
 */
  GreeLogLevelWarn = 50,
/**
 * GreeLogLevelInfo will show most any log message, no matter how verbose 
 * or purely informational.
 */
  GreeLogLevelInfo = 100,
} GreeLogLevel;

/**
 * @brief Set the verbosity of logging output
 *
 * Setting to higher numbers corresponds to more logging output. Expected value is an
 * [NSNumber numberWithInteger:GreeLogLevelPublic];  
 */ 
extern NSString* const GreeSettingLogLevel;

/**
 * @brief Toggle whether the badge values are updated when a push notification is received.
 *
 * Updating after a push notification is disabled by default.  It can be enabled by setting
 * [NSNumber numberWithBool:YES].
 */ 
extern NSString* const GreeSettingUpdateBadgeValuesAfterRemoteNotification;

/**
 * If you are including libGreeWallet.a and intend to use GreeWallet functionality you must specify
 * [NSNumber numberWithBool:YES]. By default GreeWallet is disabled.
 */ 
extern NSString* const GreeSettingUseWallet;

/**
 * The platform AccessToken is persisted in the keychain by default (therefore it survives application uninstall.)
 * You can remove the access token when reinstalling by enabling this setting with [NSNumber numberWithBool:YES].
 */ 
extern NSString* const GreeSettingRemoveTokenWithReInstall;

/**
 To allow Grade0 users to run an application, specify [NSNumber numberWithBool:YES].
 disable is set by default.
 */ 
extern NSString* const GreeSettingEnableGrade0;

/**
 * By default, GreePlatform will follow a normal UIKit-style rotation, changing its position to match the
 * UIViewController in which it is maintained.  Changing this value to YES will allow the developer to 
 * manually set the rotation for GREE platform views.  This is useful, for example, in OpenGL games where
 * you may be locking your root view controller to portrait and performing rotations via OpenGL transforms.
 */
extern NSString* const GreeSettingManuallyRotateGreePlatform;
