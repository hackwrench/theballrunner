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

#import "AchievementCell.h"
#import "UIImageView+ShowCaseAdditions.h"
#import <QuartzCore/QuartzCore.h>

@interface AchievementCell()

@property (retain, nonatomic, readwrite) GreeAchievement* achievement;

- (void)updateLabels;
- (void)updateButton;
- (void)updateImage;
- (void)cleanUpOldImageRequest;

@end

@implementation AchievementCell
@synthesize achievementIconView = _achievementIconView;
@synthesize achievementNameLabel = _achievementNameLabel;
@synthesize scoreLabel = _scoreLabel;
@synthesize changeLockStatusButton = _changeLockStatusButton;
@synthesize achievement = _achievement;

#pragma mark Object-LifeCycle
- (void)dealloc {
  [_achievementIconView release];
  [_achievementNameLabel release];
  [_scoreLabel release];
  [_changeLockStatusButton release];
  [_achievement release];
  [super dealloc];
}

#pragma mark Public API
- (void)updateWithAchievement:(GreeAchievement*)achievement
{
  [self cleanUpOldImageRequest];
  self.achievement = achievement;
  [self updateLabels];
  [self updateButton];
  [self updateImage];
}

- (void)updateButton
{
  if (self.achievement.isUnlocked) {
    [self.changeLockStatusButton setBackgroundImage:[UIImage imageNamed:@"switch_unlock.png"] forState:UIControlStateNormal];    
  }else{
    [self.changeLockStatusButton setBackgroundImage:[UIImage imageNamed:@"switch_lock.png"] forState:UIControlStateNormal];    
  }
}

- (void)awakeFromNib
{
  self.achievementIconView.layer.masksToBounds = YES;
  self.achievementIconView.layer.cornerRadius = 5.0;
}

- (void)updateImage
{
  [self.achievementIconView showLoadingImageWithSize:self.achievementIconView.frame.size];

  [self.achievement loadIconWithBlock:^(UIImage *image, NSError *error) {
    [self.achievementIconView showImage:image withSize:self.achievementIconView.frame.size];
  }];
}

#pragma mark private methods
- (void)updateLabels
{
  self.achievementNameLabel.text = self.achievement.name;
  self.scoreLabel.text = [NSString stringWithFormat:@"%d", self.achievement.score];
}

- (void)cleanUpOldImageRequest
{
  if (self.achievement) {
    [self.achievement cancelIconLoad];
  }
}


@end
