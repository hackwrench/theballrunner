//
//  PodHelper.h
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

+ (Isgl3dMeshNode*)meshNodeFromPdfile:(NSString*)podFileName  getMesh: 
(NSString*)meshName ;
- (btCollisionShape*) getCollisionShapeForNode: (Isgl3dMeshNode *)node; 
- (btVector3*) getMinMax:(Isgl3dMeshNode*)meshNode ;

@end
