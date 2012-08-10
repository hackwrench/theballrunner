//
//  PodHelper.h
//  This class use to help us about pod file and mesh collisionshape from pod file
//
//
//
//  TheBallRunner
//



#import  "isgl3d.h"
#include "btBulletDynamicsCommon.h"
#include "btBox2dShape.h"
#include "btBulletDynamicsCommon.h"
#include "btBox2dShape.h"
#include <btShapeHull.h>


@class Isgl3dScene;
@class Isgl3dCamera;
@class Isgl3dPhysicsWorld;
@class Isgl3dDemoCameraController;
@class Isgl3dPhysicsObject3D;

class btDefaultCollisionConfiguration;
class btDbvtBroadphase;
class btCollisionDispatcher;
class btSequentialImpulseConstraintSolver;
class btCollisionShape;

@interface PodHelper : NSObject

+ (Isgl3dMeshNode*)meshNodeFromPodfile:(NSString*)podFileName  getMesh: 
(NSString*)meshName ;
+ (btCollisionShape*) getCollisionShapeForNode: (Isgl3dMeshNode *)node; 


@end
