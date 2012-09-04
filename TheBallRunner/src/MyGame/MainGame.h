//
//  MainGame.h
//  TheBallRunner
//
//  Created by Thi Huynh on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "isgl3d.h"
#import "Isgl3dViewController.h"
#import "Isgl3dView.h"
#import "Const.h"

@interface MainGame : NSObject
{
    BOOL _isPlay;
    BOOL _isStop;
    BOOL _isPause;
}

+ (MainGame*)getInstance;
- (void)runScene:(enum EnumGameScene)scene;

@end
