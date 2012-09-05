//
//  UIAlertView-Block.h
//  UnderTheSea
//
//  Created by User on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlertBlock : NSObject<UIAlertViewDelegate> {
}

@end

@interface UIAlertView(UIAlertView_Block)

+(void) clearDictBlocks;
+(id) alertViewWithOK:(NSString *) title :(NSString*)msg onOK:(void(^)(void))_onOK;
+(id) alertViewWithOKCancel:(NSString *) title :(NSString*)msg 
                           onOK:(void (^)(void))_onOK onCancel:(void (^)(void))_onCancel;
+(id) alertViewWithYesNo:(NSString *)title :(NSString *)msg 
                   onYes:(void (^)(void))_onYes onNo:(void(^)(void))_onNo;

@end
