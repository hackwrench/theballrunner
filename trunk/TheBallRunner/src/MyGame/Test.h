//
//  Test.h
//  TheBallRunner
//
//  Created by Thi Huynh on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import  "isgl3d.h"
#import "Isgl3dView.h"
#include "btBulletDynamicsCommon.h"
#include "btBox2dShape.h"



@class Isgl3dScene;
@class Isgl3dCamera;
@class Isgl3dPhysicsWorld;
@class Isgl3dDemoCameraController;
@class Isgl3dPhysicsObject3D;

class btDefaultCollisionConfiguration;
class btDbvtBroadphase;
class btCollisionDispatcher;
class btSequentialImpulseConstraintSolver;
class btDiscreteDynamicsWorld;
class btCollisionShape;

@interface Test : Isgl3dBasic3DView <UIGestureRecognizerDelegate>
{
    
    
    UITapGestureRecognizer *_sceneTapGestureRecognizer;
    UITapGestureRecognizer *_nodeTapGestureRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
    UIRotationGestureRecognizer *_rotationGestureRecognizer;
    
    
	btDefaultCollisionConfiguration * _collisionConfig;
	btDbvtBroadphase * _broadphase;
	btCollisionDispatcher * _collisionDispatcher;
	btSequentialImpulseConstraintSolver * _constraintSolver;
	btDiscreteDynamicsWorld * _discreteDynamicsWorld;
    
	Isgl3dPhysicsWorld * _physicsWorld;
    
	Isgl3dNode * _cubesNode;
	Isgl3dNode * _spheresNode;
    Isgl3dNode * _torusNode;
    
    
	NSDate * _lastStepTime;
    
	NSMutableArray * _physicsObjects;
    
	Isgl3dTextureMaterial * _beachBallMaterial;
	Isgl3dTextureMaterial * _isglLogo;
    Isgl3dColorMaterial *_standardMaterial;
	
	Isgl3dShadowCastingLight * _light;
	
	Isgl3dSphere * _sphereMesh;
	Isgl3dCube * _cubeMesh;
	
    //camera
    Isgl3dDemoCameraController * _cameraController;
    Isgl3dCamera * _staticCamera;
	Isgl3dFollowCamera * _followCamera;
	
	float _angle;
    
    Isgl3dMeshNode * _ballNode;
    Isgl3dMeshNode * _torus;
    btCollisionShape * _ballShape;
    Isgl3dPhysicsObject3D* player;
    Isgl3dPhysicsObject3D * _plane;
    
    //animationcontrol
    Isgl3dAnimationController * _animationController;
    
    
    
    //touch location
    CGPoint _touchLocation;
    
    BOOL isMoving;
    BOOL isJumping;
    BOOL isStart;
    
    int _numObstacle;
}

@end
