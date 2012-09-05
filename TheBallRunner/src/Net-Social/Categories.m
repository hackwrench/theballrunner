//
//  Categories.m
//  UnderTheSea
//
//  Created by User on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "Categories.h"

@implementation CCMenu(Override)


-(void) alignItemsInColumns: (NSNumber *) columns vaList: (va_list) args
{
	NSMutableArray *rows = [[NSMutableArray alloc] initWithObjects:columns, nil];
	columns = va_arg(args, NSNumber*);
	while(columns) {
        [rows addObject:columns];
		columns = va_arg(args, NSNumber*);
	}
    
	int height = -5;
    NSUInteger row = 0, rowHeight = 0, columnsOccupied = 0, rowColumns;
	CCMenuItem *item;
    for (item in ((CCMenu*)self).children)
    {
		NSAssert( row < [rows count], @"Too many menu items for the amount of rows/columns.");
        
		rowColumns = [(NSNumber *) [rows objectAtIndex:row] unsignedIntegerValue];
		NSAssert( rowColumns, @"Can't have zero columns on a row");
        
		rowHeight = fmaxf(rowHeight, item.contentSize.height);
		++columnsOccupied;
        
		if(columnsOccupied >= rowColumns) {
			height += rowHeight + 5;
            
			columnsOccupied = 0;
			rowHeight = 0;
			++row;
		}
	}
	NSAssert( !columnsOccupied, @"Too many rows/columns for available menu items." );
    
	CGSize winSize = [[CCDirector sharedDirector] winSize];
    
	row = 0; rowHeight = 0; rowColumns = 0;
	float w, x, y = height / 2;
    
    int keepUpRowColumn=-1;
    
    for (item in ((CCMenu*)self).children) 
    {
		if(rowColumns == 0) {
			rowColumns = [(NSNumber *) [rows objectAtIndex:row] unsignedIntegerValue];
            if (keepUpRowColumn<0) keepUpRowColumn=rowColumns;
            else rowColumns=keepUpRowColumn;
            
			w = winSize.width / (1 + rowColumns);
			x = w;
		}
        
        
		CGSize itemSize = item.contentSize;
		rowHeight = fmaxf(rowHeight, itemSize.height);

        //if (arr.count<5) [arr addObject:[NSNumber numberWithFloat:y]];
        //else 
         //   y=[[arr objectAtIndex:rowColumns] floatValue];

        [item setPosition:ccp(x - winSize.width / 2,
							  y - itemSize.height / 2)];
        
		x += w-20;
		++columnsOccupied;
		
		if(columnsOccupied >= rowColumns) {
			y -= rowHeight + 5;
			
			columnsOccupied = 0;
			rowColumns = 0;
			rowHeight = 0;
			++row;
		}
	}
    
	[rows release];
}


@end


@implementation GKLeaderboardViewController (Override)

//*
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return (interfaceOrientation==CCDeviceOrientationLandscapeRight);
}
//*/

@end


@implementation GKAchievementViewController (Override)

//*
-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return (interfaceOrientation==CCDeviceOrientationLandscapeRight);
}
//*/

@end



@implementation CCTouchDispatcher (Override)
static CCNode* exclusiveNode_=nil;
static NSMutableArray *queueExclusives_=nil;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[CCDirector sharedDirector] openGLView].isExclusiveTouch) return;
    
	if( dispatchEvents )
		[self touches:touches withEvent:event withTouchType:kCCTouchBegan];
}


- (void)registerExclusive:(CCNode*)node
{
    if (queueExclusives_==nil) queueExclusives_=[[NSMutableArray alloc] initWithCapacity:4];
    
    [queueExclusives_ addObject:node];
    exclusiveNode_=[queueExclusives_ objectAtIndex:0];
}

- (void)unregisterExclusive
{
    [queueExclusives_ removeObjectAtIndex:0];
    //[exclusiveNode_ release];
    
    if (queueExclusives_.count<1) exclusiveNode_=nil;
    else exclusiveNode_=[queueExclusives_ objectAtIndex:0];
}

-(void) touches:(NSSet*)touches withEvent:(UIEvent*)event withTouchType:(unsigned int)idx
{
	NSAssert(idx < 4, @"Invalid idx value");
    
	id mutableTouches;
	locked = YES;
	
	// optimization to prevent a mutable copy when it is not necessary
	unsigned int targetedHandlersCount = [targetedHandlers count];
	unsigned int standardHandlersCount = [standardHandlers count];	
	BOOL needsMutableSet = (targetedHandlersCount && standardHandlersCount);
	
	mutableTouches = (needsMutableSet ? [touches mutableCopy] : touches);
    
	struct ccTouchHandlerHelperData helper = handlerHelperData[idx];
	//
	// process the target handlers 1st
	//
	if( targetedHandlersCount > 0 ) {
		for( UITouch *touch in touches ) {
			for(CCTargetedTouchHandler *handler in targetedHandlers) {
				
                if (exclusiveNode_!=nil)
                {
                    bool boo=NO;
                    CCNode *node=handler.delegate;
                    while (node!=nil) {
                        if (node==exclusiveNode_) {boo=YES;break;}
                        node=node.parent;
                    }
                    if (!boo) continue;
                }
                
				BOOL claimed = NO;
				if( idx == kCCTouchBegan ) {
					claimed = [handler.delegate ccTouchBegan:touch withEvent:event];
					if( claimed )
						[handler.claimedTouches addObject:touch];
				} 
				
				// else (moved, ended, cancelled)
				else if( [handler.claimedTouches containsObject:touch] ) {
					claimed = YES;
					if( handler.enabledSelectors & helper.type )
						[handler.delegate performSelector:helper.touchSel withObject:touch withObject:event];
					
					if( helper.type & (kCCTouchSelectorCancelledBit | kCCTouchSelectorEndedBit) )
						[handler.claimedTouches removeObject:touch];
				}
                
				if( claimed && handler.swallowsTouches ) {
					if( needsMutableSet )
						[mutableTouches removeObject:touch];
					break;
				}
			}
		}
	}
	
	//
	// process standard handlers 2nd
	//
	if( standardHandlersCount > 0 && [mutableTouches count]>0 ) {
		for( CCTouchHandler *handler in standardHandlers ) {
            if (exclusiveNode_!=nil)
            {
                bool boo=NO;
                CCNode *node=handler.delegate;
                while (node!=nil) {
                    if (node==exclusiveNode_) {boo=YES;break;}
                    node=node.parent;
                }
                if (!boo) continue;
            }
            
			if( handler.enabledSelectors & helper.type )
				[handler.delegate performSelector:helper.touchesSel withObject:mutableTouches withObject:event];
		}
	}
	if( needsMutableSet )
		[mutableTouches release];
	
	//
	// Optimization. To prevent a [handlers copy] which is expensive
	// the add/removes/quit is done after the iterations
	//
	locked = NO;
	if( toRemove ) {
		toRemove = NO;
		for( id delegate in handlersToRemove )
			[self forceRemoveDelegate:delegate];
		[handlersToRemove removeAllObjects];
	}
	if( toAdd ) {
		toAdd = NO;
		for( CCTouchHandler *handler in handlersToAdd ) {
			Class targetedClass = [CCTargetedTouchHandler class];
			if( [handler isKindOfClass:targetedClass] )
				[self forceAddHandler:handler array:targetedHandlers];
			else
				[self forceAddHandler:handler array:standardHandlers];
		}
		[handlersToAdd removeAllObjects];
	}
	if( toQuit ) {
		toQuit = NO;
		[self forceRemoveAllDelegates];
	}
}


@end



@implementation CCMenuItemImage (Override)

-(id) initFromNormalImage: (NSString*) normalI selectedImage:(NSString*)selectedI disabledImage: (NSString*) disabledI target:(id)t selector:(SEL)sel
{
	CCNode<CCRGBAProtocol> *normalImage = [CCSprite spriteWithFile:normalI];
	CCNode<CCRGBAProtocol> *selectedImage = nil;
	CCNode<CCRGBAProtocol> *disabledImage = nil;
    
	if( selectedI )
		selectedImage = [CCSprite spriteWithFile:selectedI]; 
    else 
    {    
        selectedImage=[CCSprite spriteWithFile:normalI];
        [selectedImage setOpacity:150];
    }
    
	if(disabledI)
		disabledImage = [CCSprite spriteWithFile:disabledI];
    
	return [self initFromNormalSprite:normalImage selectedSprite:selectedImage disabledSprite:disabledImage target:t selector:sel];
}

@end


#pragma mark NSTimer+Override
@implementation TimerBlock

-(id) initWithBlock:(void(^)(NSTimer*))_onExec
{
    self=[super init];
    onExec=[_onExec copy];
    
    return self;
}

-(void) execWithTimer:(NSTimer*)timer
{
    if (onExec!=nil) onExec(timer);
}

-(void) dealloc
{
    [onExec release];
    [super dealloc];
}
@end


@implementation NSTimer(Override)
+(id) timerWithTimeout:(float)seconds andBlock:(void(^)(NSTimer*))onTimeout
{
    TimerBlock *tmrBlock=[[TimerBlock alloc] initWithBlock:onTimeout];    
    [tmrBlock autorelease];
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:tmrBlock selector:@selector(execWithTimer:) userInfo:nil repeats:NO];
}

+(id) timerWithInterval:(float)seconds andBlock:(void(^)(NSTimer*))onInterval
{
    TimerBlock *tmrBlock=[[TimerBlock alloc] initWithBlock:onInterval];    
    [tmrBlock autorelease];
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:tmrBlock selector:@selector(execWithTimer:) userInfo:nil repeats:YES];    
}
@end
