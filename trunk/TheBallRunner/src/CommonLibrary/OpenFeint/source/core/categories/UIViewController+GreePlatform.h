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

/**
 * @file UIViewController+GreePlatform.h
 * The GreePlatform category on UIViewController exposes methods for
 * managing the display of GREE platform views such as the dashboard,
 * notification board, widget, and popups.
 */

#import <UIKit/UIKit.h>
#import "GreeWidget.h"

@class GreePopup;

/**
 * Enumeration for the available default views for presenting the
 * notification board.
 */
typedef enum {
  /**
   * Notification board will display notifications specific to the 
   * current game by default.
   */
  //#indocEnd "GreeNotificationBoardTypeGame" en
  GreeNotificationBoardTypeGame,
  /**
   * Notification board will display notifications for the GREE
   * social network (such as friend requests) by default.
   */
  GreeNotificationBoardTypeSNS
} GreeNotificationBoardType;

/**
 * The GreePlatform category on UIViewController is your primary interface
 * for managing GREE platform views.
 */
@interface UIViewController (GreePlatform)

/**
 @brief Present the GREE dashboard modally from the receiver.

 @param parameters  Parameters to initialize the GREE dashboard. nil is acceptable.
 @param animated    Animate the presentation if @c YES is specified.

 @note GreePlatformDelegate's greePlatformWillShowModalView will be invoked if necessary
 
 @c The following keys and their values can be specified for parameters. Other keys will be ignored.
 
 @par GameDashboard front
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeTop.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Ranking list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeRankingList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Ranking details (User list for a particular ranking)
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeRankingDetails.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 <tr><td>@ref GreeDashboardLeaderboardId</td><td>Leader board ID</td><td>Mandatory</td></tr>
 </table>
 
 @par Achievement list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeAchievementList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 <tr><td>@ref GreeDashboardUserId</td><td>User ID</td><td>Optional (If this key is not specified, the user ID of the accessing user will be set.)</td></tr>
 </table>
 
 @par Playing user/Friend list
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeUsersList.</td></tr>
 <tr><td>@ref GreeDashboardAppId</td><td>Application ID</td><td>Optional (If this key is not specified, the application ID retrieved from a running application will be set.)</td></tr>
 </table>
 
 @par Application setting
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeAppSetting.</td></tr>
 </table>
 
 @par Friend invitation
 <table>
 <tr><th>Key</th><th>Value</th><th>Setting</th></tr>
 <tr><td>@ref GreeDashboardMode</td><td>Dashboard mode</td><td>Specify @ref GreeDashboardModeUsersInvites.</td></tr>
 </table>
 */
- (void)presentGreeDashboardWithParameters:(NSDictionary*)parameters animated:(BOOL)animated;
/**
 * Present the GREE notification board modall from the receiver.
 *
 * @param type      Determines the default notifiaction board view
 * @param animated  Animate the presentation if @c YES is specified.
 * 
 * @note GreePlatformDelegate's greePlatformWillShowModalView will be invoked if necessary
 */
- (void)presentGreeNotificationBoardWithType:(GreeNotificationBoardType)type animated:(BOOL)animated;
/**
 * Dismiss any GREE dashboard or notification board presented from the receiver.
 *
 * @param animated  Animate the dismissal if @c YES is specified.
 */
- (void)dismissActiveGreeViewControllerAnimated:(BOOL)animated;

/**
 * Show a GREE popup view modally from the receiver.
 *
 * @param popup  An instance of GreePopup to be displayed.
 *
 * @see GreePopup
 *
 * @note GreePopup display will always be animated.
 */
- (void)showGreePopup:(GreePopup*)popup;
/**
 * Dismiss any GREE popup view being shown from the reeiver.
 */
- (void)dismissGreePopup;

/**
 * Show the GREE in-game widget in the receiver's view.
 * @param dataSource The widget's data source to provide screenshot image data
 * @note If you pass in nil, there will be NO screenshot button on this widget
 * @see GreeWidget
 */
- (void)showGreeWidgetWithDataSource:(id<GreeWidgetDataSource>)dataSource;

/**
 * Removes the GREE in-game widget being shown in the receiver's view.
 * @note This method has no effect if there is no displayed widget.
 */
- (void)hideGreeWidget;
/**
 * Accessor for the GREE in-game widget shown in the receiver's view.
 * @note This method will return nil if you hide the widget
 */
- (GreeWidget*)activeGreeWidget;

@end
