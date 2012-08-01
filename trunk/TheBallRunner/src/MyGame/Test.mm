//
//  Test.m
//  TheBallRunner
//
//  Created by Thi Huynh on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Test.h"
#import "Isgl3dPhysicsWorld.h"
#import "Isgl3dPhysicsObject3D.h"
#import "Isgl3dMotionState.h"
#include "Isgl3dPODImporter.h"

#import <stdlib.h>
#import <time.h>

#include "btBulletDynamicsCommon.h"
#include "btBox2dShape.h"


#define PLANE_WIDTH 1000
#define PLANE_HEIGH 20


@interface Test (PrivateMethods)

- (void) initPhysic;
- (void) createEnvirontment;
- (void) createSphere;
- (void) createCube;
- (void) createObstacle;
- (void) createPlaneWith:(float)_width _height:(float)_height;
- (void) createPlayerWithPos:(Isgl3dVector3)pos andRadius:(float)radius;
- (Isgl3dPhysicsObject3D *) createPhysicsObject:(Isgl3dMeshNode *)node shape:(btCollisionShape *)shape mass:(float)mass restitution:(float)restitution isFalling:(BOOL)isFalling;

-(Isgl3dPhysicsObject3D *) createPlayer:(Isgl3dMeshNode *)node shape:(btCollisionShape *)shape mass:(float)mass restitution:(float)restitution isFalling:(BOOL)isFalling;

- (void)sceneTap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)nodeTap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)pinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer;
- (void)rotationGesture:(UIRotationGestureRecognizer *)gestureRecognizer;
- (void)createPodAnimation;
- (void)collisionCallBack;

@end

@implementation Test

- (id) init
{
	
	if ((self = [super init])) 
    {
		_physicsObjects = [[NSMutableArray alloc] init];
	 	_lastStepTime = [[NSDate alloc] init];
        
	 	srandom(time(NULL));
        
        
        //set start game
        isStart=NO;
        _numObstacle=0;
		
        
        //set up gesture
        _sceneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sceneTap:)];
        _sceneTapGestureRecognizer.delegate = self;
        [[Isgl3dDirector sharedInstance] addGestureRecognizer:_sceneTapGestureRecognizer forNode:nil];
        
        _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        _pinchGestureRecognizer.delegate = self;
        _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGesture:)];
        _rotationGestureRecognizer.delegate = self;
        
             
		// Enable shadow rendering
		[Isgl3dDirector sharedInstance].shadowRenderingMethod = Isgl3dShadowPlanar;
		[Isgl3dDirector sharedInstance].shadowAlpha = 0.4;
        
        
		// Create physics world with discrete dynamics
		_collisionConfig = new btDefaultCollisionConfiguration();
		_broadphase = new btDbvtBroadphase();
		_collisionDispatcher = new btCollisionDispatcher(_collisionConfig);
		_constraintSolver = new btSequentialImpulseConstraintSolver;
		_discreteDynamicsWorld = new btDiscreteDynamicsWorld(_collisionDispatcher, _broadphase, _constraintSolver, _collisionConfig);
		_discreteDynamicsWorld->setGravity(btVector3(0,-10,0));
        
        
		_physicsWorld = [[Isgl3dPhysicsWorld alloc] init];
		[_physicsWorld setDiscreteDynamicsWorld:_discreteDynamicsWorld];
		[self.scene addChild:_physicsWorld];
        
        
        
		// Create textures - matearial
		_beachBallMaterial = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"BeachBall.png" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
		_isglLogo = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"crate.png" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
        _standardMaterial = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"cardboard.png" shininess:0.9];
    
        //create mesh one time for multi object cube
		float width = 2.0;
        _cubeMesh = [[Isgl3dCube alloc] initWithGeometry:width height:width depth:width nx:2 ny:2];
        
		// Create two nodes for the different meshes from physic world
		_cubesNode = [[_physicsWorld createNode] retain];
		
        // Create sphere mesh node to render stars(SKY): double sided so that the stars are rendered "inside", and without lighting
		Isgl3dSphere * sphere = [Isgl3dSphere meshWithGeometry:600 longs:32 lats:8];
		Isgl3dTextureMaterial * starsMaterial = [Isgl3dTextureMaterial materialWithTextureFile:@"stars.png" shininess:0 precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
		Isgl3dMeshNode * stars = [self.scene createNodeWithMesh:sphere andMaterial:starsMaterial];
		stars.doubleSided = YES;
		stars.lightingEnabled = NO;     
        
        
        //create plane
        [self createPlaneWith:PLANE_WIDTH _height:PLANE_HEIGH];
        
        // create player
        [self createPlayerWithPos:iv3(0,5,-450 ) andRadius:1];
        
        //create animation
        [self createPodAnimation];
        
        //create obstacle
        [self createObstacle];
        
        
        //light setting
		_light  = [[Isgl3dShadowCastingLight alloc] initWithHexColor:@"111111" diffuseColor:@"FFFFFF" specularColor:@"FFFFFF" attenuation:0.003];
		[self.scene addChild:_light];
		_light.position = iv3(10, 100, 10);
        
		_light.planarShadowsNode = _plane.node;
        
        
		[self setSceneAmbient:@"666666"];
        
        
        [self.camera setPosition:iv3(0,_ballNode.position.y+2,_ballNode.position.z-7)];
        [self.camera setLookAt:_ballNode.position];
        
        
		// Schedule updates
		[self schedule:@selector(tick:)];
	}
	
	return self;
}

//================= getsture recognize ================================= //
#pragma mark UIGestureRecognizerDelegate methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    if ((gestureRecognizer == _rotationGestureRecognizer) || (otherGestureRecognizer == _rotationGestureRecognizer))
        return NO;
    
    return YES;
}


#pragma mark GestureRecognizer action methods
- (void)sceneTap:(UITapGestureRecognizer *)gestureRecognizer 
{
    CGPoint point = [gestureRecognizer locationInView:[Isgl3dDirector sharedInstance].openGLView];
    NSLog(@"tap at position (%f - %f)",point.x,point.y);
    if(point.x <= 240)
    {
        player.rigidBody->setLinearVelocity(btVector3(0,0,30));
        player.rigidBody->applyCentralImpulse(btVector3(30,0,0));
    }
    else 
    {
        player.rigidBody->setLinearVelocity(btVector3(0,0,30));
        player.rigidBody->applyCentralImpulse(btVector3(-30,0,0));
    }
}

- (void)nodeTap:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:[Isgl3dDirector sharedInstance].openGLView];
    NSLog(@"tap at position (%f , %f)",point.x,point.y);
    
    
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer 
{
	if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
	{
        
	}
}

- (void)rotationGesture:(UIRotationGestureRecognizer *)gestureRecognizer 
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) 
    {
        [gestureRecognizer setRotation:0];
    }
}


/********* touch object begin *****************************/
- (void) playerTouch:(Isgl3dEvent3D *)event 
{
    // Get the object associated with the 3D event.
    // Isgl3dNode * object = event.object;
    //self.camera = _followCamera;
    
    UITouch * touch = [[event.touches allObjects] objectAtIndex:0];
    CGPoint uiPoint = [touch locationInView:touch.view];
    _touchLocation = [self convertUIPointToView:uiPoint];
    
    if(!isMoving)
    {
        //player.rigidBody->applyCentralImpulse(btVector3(dir.x-pos.x,dir.y-pos.y,dir.z-pos.z)/2);
        player.rigidBody->setLinearVelocity(btVector3(0,0,30));
        isMoving=YES;
    }
    
    if(player.node.position.y < 2 )
    {
        
        player.rigidBody->setLinearVelocity(btVector3(0,10,30));
        
    } 

    //set start game
    isStart=YES;
    
}

/******************* touch object release ***********************/
- (void) playerTouchRelease:(Isgl3dEvent3D *)event 
{
    
}


/******************** game update **********************************/
- (void) tick:(float)dt 
{
    
    
    //COLLISION TEST
    [_physicsWorld collisionTest];
    
    //set camera look at higher than target
    [self.camera setLookAt:iv3(_ballNode.position.x,_ballNode.position.y+2,_ballNode.position.z)];
    //set camera position is behind and higher than the target
    [self.camera setPositionValues:_ballNode.position.x y:_ballNode.position.y+2 z:_ballNode.position.z-7];
    
     
	// Get time since last step
	NSDate * currentTime = [[NSDate alloc] init];
	
	NSTimeInterval timeInterval = [currentTime timeIntervalSinceDate:_lastStepTime];
    
	// Add new object every 0.5 seconds
	if (timeInterval > 2 && _numObstacle < 30) 
    {
        //[self createCube];
        _numObstacle++;
		[_lastStepTime release];
		_lastStepTime = currentTime;
	} 
    else 
    {
		[currentTime release];
	}
    
	// Remove objects that have fallen too low
	NSMutableArray * objectsToDelete = [[NSMutableArray alloc] init];
	
	for (Isgl3dPhysicsObject3D * physicsObject in _physicsObjects) 
    {
		if (physicsObject.node.y < -10) 
        {
			[objectsToDelete addObject:physicsObject];
		}
		
	}
    
	for (Isgl3dPhysicsObject3D * physicsObject in objectsToDelete) 
    {
		[_physicsWorld removePhysicsObject:physicsObject];
		[_physicsObjects removeObject:physicsObject];
	}
	
	[objectsToDelete release];
    
	
	// update camera
	//[_cameraController update];
}

//================== create plane and wall ====================//
- (void) createPlaneWith:(float)_width _height:(float)_height
{
    
    //create material
    Isgl3dTextureMaterial * woodMaterial = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"wood.png" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:YES repeatY:YES];
    
    Isgl3dTextureMaterial * woodMaterial1 = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"wall.png" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:YES repeatY:YES];
    
    
	
    // Create the ground surface
    Isgl3dPlane * plane = [[Isgl3dPlane alloc] initWithGeometry:_height height:_width nx:_height ny:_width];
    btCollisionShape* groundShape = new btBox2dShape(btVector3(_height/2, _width/2, 0));
    Isgl3dMeshNode * node = [_physicsWorld createNodeWithMesh:plane andMaterial:[woodMaterial autorelease]];
    [node setRotation:-90 x:1 y:0 z:0];
    node.position = iv3(-0, 0, 0);
    _plane = [self createPhysicsObject:node shape:groundShape mass:0 restitution:0.6 isFalling:NO];
    
    
    //create wall left
    Isgl3dPlane * wallLeft = [[Isgl3dPlane alloc] initWithGeometry:_width height:_height/2 nx:_width ny:_height/2];
    btCollisionShape* wallLeftShape = new btBox2dShape(btVector3(_width/2, _height/4, 0));
    Isgl3dMeshNode * wallLeftNode = [_physicsWorld createNodeWithMesh:wallLeft andMaterial:[woodMaterial1 autorelease]];
    [wallLeftNode setRotation:-90 x:0 y:1 z:0];
    wallLeftNode.position = iv3(_height/2, 0, 0);
    [self createPhysicsObject:wallLeftNode shape:wallLeftShape mass:0 restitution:0.6 isFalling:NO];
    
    //create wall right
    Isgl3dPlane * wallRight = [[Isgl3dPlane alloc] initWithGeometry:_width height:_height/2 nx:_width ny:_height/2];
    btCollisionShape* wallRightShape = new btBox2dShape(btVector3(_width/2, _height/4, 0));
    Isgl3dMeshNode * wallRightNode = [_physicsWorld createNodeWithMesh:wallRight andMaterial:[woodMaterial1 autorelease]];
    [wallRightNode setRotation:90 x:0 y:1 z:0];
    wallRightNode.position = iv3(-_height/2, 0, 0);
    [self createPhysicsObject:wallRightNode shape:wallRightShape mass:0 restitution:0.6 isFalling:NO];
    
    // Create the back wall
    
    Isgl3dCube* _wallMesh = [[Isgl3dCube alloc] initWithGeometry:10 height:10 depth:1 nx:10 ny:10];
    
    btCollisionShape* wallShape = new btBox2dShape(btVector3(5, 5, 0.5));
    Isgl3dMeshNode * wallNode = [_physicsWorld createNodeWithMesh:_wallMesh andMaterial:[woodMaterial autorelease]];
    //[wallNode setRotation:0 x:1 y:0 z:0];
    wallNode.position = iv3(0, 0, _width/2);
    [self createPhysicsObject:wallNode shape:wallShape mass:0 restitution:0.6 isFalling:NO];
    
}

//================== create pod animation ===================//
- (void)createPodAnimation
{
    
    Isgl3dPODImporter * podImporter = [Isgl3dPODImporter podImporterWithFile:@"man.pod"];
    
    //Isgl3dPODImporter * importer = [Isgl3dPODImporter podImporterWithFile:@"Scene_float.pod"];
    
    
    // Modify texture files
    [podImporter modifyTexture:@"body.bmp" withTexture:@"Body.pvr"];
    [podImporter modifyTexture:@"legs.bmp" withTexture:@"Legs.pvr"];
    [podImporter modifyTexture:@"belt.bmp" withTexture:@"Belt.pvr"];
	
    // Create skeleton node	
    Isgl3dSkeletonNode * skeleton = [self.scene createSkeletonNode];
    skeleton.position = iv3(0, 0 , -450);
    [skeleton setScale:0.05];
    //run action
    id action1 = [Isgl3dActionMoveTo actionWithDuration:50 position:iv3(0,0,1000)];
    [skeleton runAction:action1];
    
    // Add meshes to skeleton
    [podImporter addMeshesToScene:skeleton];
    [skeleton setAlphaWithChildren:1];
    [podImporter addBonesToSkeleton:skeleton];
    [skeleton enableShadowCastingWithChildren:YES];
	
    // Add animation controller
    _animationController = [[Isgl3dAnimationController alloc] initWithSkeleton:skeleton andNumberOfFrames:[podImporter numberOfFrames]];
    [_animationController start];
	
    
    
}

//================ create player ===========================//
- (void) createPlayerWithPos:(Isgl3dVector3)pos andRadius:(float)radius
{
    
    
    //create mesh first
    _sphereMesh = [[Isgl3dSphere alloc] initWithGeometry:radius longs:16 lats:16];
    
    //create node later with physic world
    _spheresNode = [[_physicsWorld createNode] retain];
    
    // create collision shape
    _ballShape = new btSphereShape(_sphereMesh.radius);
    
    //create meshnode 
    _ballNode = [_spheresNode createNodeWithMesh:_sphereMesh andMaterial:_beachBallMaterial];
    
    
    _ballNode.interactive = YES;
    _ballNode.position = pos;
    _ballNode.enableShadowCasting = YES;
    
    //add touch listener
    //[_ballNode addEvent3DListener:self method:@selector(playerTouch:) forEventType:TOUCH_EVENT];
    [_ballNode addGestureRecognizer:_nodeTapGestureRecognizer];
    
    //create physic object
    player= [self createPlayer:_ballNode shape:_ballShape mass:6 restitution:0.9 isFalling:NO];
    
    //set intertractvwith touch
    player.node.interactive = YES;
    [player.node addEvent3DListener:self method:@selector(playerTouch:) forEventType:TOUCH_EVENT];
    [player.node addEvent3DListener:self method:@selector(playerTouchRelease:) forEventType:RELEASE_EVENT];
    
    
}

//============== create sphere ========================
- (void) createSphere 
{
	
	btCollisionShape * sphereShape = new btSphereShape(_sphereMesh.radius);
	Isgl3dMeshNode * node = [_spheresNode createNodeWithMesh:_sphereMesh andMaterial:_beachBallMaterial];
	[self createPhysicsObject:node shape:sphereShape mass:0.5 restitution:0.9 isFalling:YES]; 
    
	node.enableShadowCasting = YES;
	
}

//=============== create cube =========================
- (void) createCube 
{
	
	btCollisionShape* boxShape = new btBoxShape(btVector3(_cubeMesh.width / 2, _cubeMesh.height / 2, _cubeMesh.depth / 2));
	Isgl3dMeshNode * node = [_cubesNode createNodeWithMesh:_cubeMesh andMaterial:_isglLogo];
    //_cubesNode.position =iv3(0, 2, -100);
	[self createPhysicsObject:node shape:boxShape mass:100 restitution:0.4 isFalling:YES]; 
	node.enableShadowCasting = YES;
}


//================= create obstacle ===================
- (void) createObstacle
{
    
    Isgl3dTextureMaterial * _material = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"cardboard.jpg" shininess:0.9 precision:Isgl3dTexturePrecisionMedium repeatX:YES repeatY:YES];
    
    _standardMaterial = [[Isgl3dTextureMaterial alloc] initWithTextureFile:@"cardboard.png" shininess:0.9];
    
    Isgl3dCube* _obstacleMesh = [[Isgl3dCube alloc] initWithGeometry:5 height:5 depth:2 nx:5 ny:5];
    
    for(int i=0;i<20 ;i ++)
    {
        btCollisionShape* _obstacleShape = new btBox2dShape(btVector3(2.5, 2.5, 1));
        Isgl3dMeshNode * wallNode = [_physicsWorld createNodeWithMesh:_obstacleMesh andMaterial:[_material autorelease]];
        //[wallNode setRotation:0 x:1 y:0 z:0];
        wallNode.position = iv3(0, 0, -(PLANE_WIDTH/2 -100) + i*100);
        [self createPhysicsObject:wallNode shape:_obstacleShape mass:0 restitution:0.6 isFalling:NO];
        
    }
    
    
}

//============= create object =======================
- (Isgl3dPhysicsObject3D *) createPhysicsObject:(Isgl3dMeshNode *)node shape:(btCollisionShape *)shape mass:(float)mass restitution:(float)restitution isFalling:(BOOL)isFalling 
{
    
	if (isFalling) 
    {
		[node setPositionValues:1.5 - (3.0 * random() / RAND_MAX) y:10 + (10.0 * random() / RAND_MAX) z:1.5 - (3.0 * random() / RAND_MAX)];
	}
    
	Isgl3dMotionState * motionState = new Isgl3dMotionState(node);
	
	btVector3 localInertia(0, 0, 0);
	shape->calculateLocalInertia(mass, localInertia);
	btRigidBody * rigidBody = new btRigidBody(mass, motionState, shape, localInertia);
	rigidBody->setRestitution(restitution);
    rigidBody->setCompanionId(888);
	Isgl3dPhysicsObject3D * physicsObject = [[Isgl3dPhysicsObject3D alloc] initWithNode:node andRigidBody:rigidBody];
	[_physicsWorld addPhysicsObject:physicsObject];
    
	[_physicsObjects addObject:physicsObject];
	
	return [physicsObject autorelease];
}


//===============create player==========================
-(Isgl3dPhysicsObject3D *) createPlayer:(Isgl3dMeshNode *)node shape:(btCollisionShape *)shape mass:(float)mass restitution:(float)restitution isFalling:(BOOL)isFalling
{
    // [node setPositionValues:0 y:5 z:-50];
    
	Isgl3dMotionState * motionState = new Isgl3dMotionState(node);
    
	btVector3 localInertia(0, 0, 0);
    
	shape->calculateLocalInertia(mass, localInertia);
    
	btRigidBody * rigidBody = new btRigidBody(mass, motionState, shape, localInertia);
    
	rigidBody->setRestitution(restitution);
    
    rigidBody->setCompanionId(999);
    
	Isgl3dPhysicsObject3D * physicsObject = [[Isgl3dPhysicsObject3D alloc] initWithNode:node andRigidBody:rigidBody];
	
    [_physicsWorld addPhysicsObject:physicsObject];
    
    
	//[_physicsObjects addObject:physicsObject];
	
	return [physicsObject autorelease];
    
}

//=============== collision call back =======================
- (void)collisionCallBack
{
    
    
}

/************* dealloc ********************************/

- (void) dealloc
{
	
    
    [_animationController release];
    
	delete _discreteDynamicsWorld;
	delete _collisionConfig;
	delete _broadphase;
	delete _collisionDispatcher;
	delete _constraintSolver;
	
	[_physicsObjects release];
	[_physicsWorld release];
	[_beachBallMaterial release];
	[_isglLogo release];
	[_sphereMesh release];
	[_cubeMesh release];
    [_ballNode release];
    
	[_light release];
	
	[_cubesNode release];
	[_spheresNode release];
    
	[super dealloc];
}

- (void) onActivated 
{
	// Add camera controller to touch-screen manager
	//[[Isgl3dTouchScreen sharedInstance] addResponder:_cameraController];
}

- (void) onDeactivated 
{
	// Remove camera controller from touch-screen manager
	//[[Isgl3dTouchScreen sharedInstance] removeResponder:_cameraController];
}


@end


