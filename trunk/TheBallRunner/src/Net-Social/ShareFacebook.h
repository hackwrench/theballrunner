//
//  ShareFacebook.h
//  UnderTheSea
//
//  Created by hung.huynh on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "User.h"
#import "Facebook.h"

@interface ShareFacebook : CCLayer<FBDialogDelegate,FBRequestDelegate,FBSessionDelegate>
{
    Facebook *facebook;
    bool loggedIn;
    int countShow;
}

-(void)createMenuFacebook:(id)layer;
- (BOOL) postImage;

@end
