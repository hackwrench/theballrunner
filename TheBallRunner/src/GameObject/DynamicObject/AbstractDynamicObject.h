//
//  AbstractDynamicObject.h
//  TheBallRunner
//
//  Created by Thi Huynh on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import  "isgl3d.h"
#import  "Isgl3dView.h"
#import  "PodHelper.h"

@interface AbstractDynamicObject : NSObject
{
    Isgl3dMaterial          *_normalMaterial;
    Isgl3dNode              *_node;
    Isgl3dMeshNode          *_meshNode;
    
    Isgl3dVector3           *_position;
    Isgl3dVector3           *_scale;
    Isgl3dVector3           *_velocity;
    Isgl3dVector3           *_direction;
    
    btRigidBody             *_body;
    btCollisionShape        *_shape;
    Isgl3dPhysicsObject3D   *_physicObject;
    
    
    int                     _mass;
    BOOL                    _isRunning;
    BOOL                    _isFalling;
    BOOL                    _isJumping;

}

- (void)initObjectWith:(Isgl3dVector3*)pos  scale:(float)scale  mass:(float)mass;

@end
