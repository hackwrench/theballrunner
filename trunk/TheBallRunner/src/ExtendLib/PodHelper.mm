//
//  PodHelper.m
//  TheBallRunner
//


#import "PodHelper.h"
#import "Isgl3dPhysicsWorld.h"
#import "Isgl3dPhysicsObject3D.h"
#import "Isgl3dMotionState.h"
#include "Isgl3dPODImporter.h"

#import <stdlib.h>
#import <time.h>

#include "btBulletDynamicsCommon.h"
#include "btBox2dShape.h"


@interface PodHelper()
+ (btVector3*) getMinMax:(Isgl3dMeshNode*)meshNode ;

@end

@implementation PodHelper

+ (Isgl3dMeshNode*)meshNodeFromPodfile:(NSString*)podFileName  getMesh:(NSString*)meshName 
{
    Isgl3dPODImporter * importer = [Isgl3dPODImporter 
                                    podImporterWithFile:podFileName]; 
    [importer buildSceneObjects]; 
    //[importer addMeshesToScene:self.scene]; // to import all meshes into the scene 
    [importer printPODInfo]; 
    return [importer meshNodeWithName:meshName]; 
}

//Here is the getMinMax method to obtain the points of a mesh node: 

+ (btVector3*) getMinMax:(Isgl3dMeshNode*)meshNode 
                    minX:(float*)minX 
                    maxX:(float*)maxX 
                    minY:(float*)minY 
                    maxY:(float*)maxY 
                    minZ:(float*)minZ 
                    maxZ:(float*)maxZ 
          logCoordinates:(bool)log 
{ 
    
    int _numVertices = meshNode.mesh.numberOfVertices; 
    Isgl3dGLVBOData* _vboData = meshNode.mesh.vboData; 
    
    unsigned int stride = _vboData.stride; 
    unsigned int positionOffsetX = _vboData.positionOffset; 
    unsigned int positionOffsetY = _vboData.positionOffset + 
    sizeof(float); 
    unsigned int positionOffsetZ = _vboData.positionOffset + 2 * 
    sizeof(float); 
    unsigned int normalOffsetX = _vboData.normalOffset; 
    unsigned int normalOffsetY = _vboData.normalOffset + 
    sizeof(float); 
    unsigned int normalOffsetZ = _vboData.normalOffset + 2 * 
    sizeof(float); 
    
    // Get raw vertex data array from mesh 
    unsigned char* vertexData = meshNode.mesh.vertexData; 
    
    btVector3* points = (btVector3*)malloc(_numVertices * 
                                           sizeof(btVector3)); 
    
    // Iterate over all the vertex data in the passed mesh and add it to the keyframe vertex data array 
    //float MinX, MaxX, MinY, MaxY, MinZ, MaxZ; 
    /* Inialise values to first vertex */ 
    *minX=MAXFLOAT;        *maxX=-MAXFLOAT; 
    *minY=MAXFLOAT;        *maxY=-MAXFLOAT; 
    *minZ=MAXFLOAT;        *maxZ=-MAXFLOAT; 
    
    for (unsigned int i = 0; i < _numVertices; i++) { 
        Isgl3dVector3 _position, _normal; 
        _position.x = *((float*)&vertexData[stride * i + 
                                            positionOffsetX]); 
        _position.y = *((float*)&vertexData[stride * i + 
                                            positionOffsetY]); 
        _position.z = *((float*)&vertexData[stride * i + 
                                            positionOffsetZ]); 
        _normal.x   = *((float*)&vertexData[stride * i + 
                                            normalOffsetX  ]); 
        _normal.y   = *((float*)&vertexData[stride * i + 
                                            normalOffsetY  ]); 
        _normal.z   = *((float*)&vertexData[stride * i + 
                                            normalOffsetZ  ]); 
        
        points[i] = btVector3(_position.x, _position.y, _position.z); 
        // 
        if(log) 
        { 
            Isgl3dLog(Info,@"%i position x = %f y = %f z = %f", i, 
                      _position.x, _position.y, _position.z); 
            Isgl3dLog(Info,@"%i normal x = %f y = %f z = %f", i, 
                      _normal.x, _normal.y, _normal.z); 
        } 
        
        /* Minimum and Maximum X */ 
        if (_position.x < *minX) 
            *minX = _position.x; 
        if (_position.x > *maxX) 
            *maxX = _position.x; 
        
        /* Minimum and Maximum Y */ 
        if (_position.y < *minY) 
            *minY = _position.y; 
        if (_position.y > *maxY) 
            *maxY = _position.y; 
        
        /* Minimum and Maximum Z */ 
        if (_position.z < *minZ) 
            *minZ = _position.z; 
        if (_position.z > *maxZ) 
            *maxZ = _position.z; 
    } 
    return points; 
} 
/****************************************************************************************
*Name: get collison shape(bullet) from a mesh node--> use for physic with mesh from model
*Input:  *Isgl3DMeshNode(Belong to Isgl3Dframework)
*Output: *btCollisionShape(Belong to Bullet physyic lib)
*
****************************************************************************************/
+ (btCollisionShape*) getCollisionShapeForNode: (Isgl3dMeshNode 
                                                 *)node 
{ 
    int numVertices = node.mesh.numberOfVertices; 
    btCollisionShape* collisionShape = nil; 
    
#ifdef USE_BTGIMPACT 
    
    
#else 
    // get the extent values of the node mesh 
    
    // first tests were with box collision shapes - therefore I needed the extents 
    float MinX, MaxX, MinY, MaxY, MinZ, MaxZ; 
    btVector3* points = [self getMinMax:node minX:&MinX maxX:&MaxX minY:&MinY maxY:&MaxY minZ:&MinZ maxZ:&MaxZ logCoordinates:NO]; 
    
    btConvexHullShape* sshape = new btConvexHullShape(&(*points)[0], 
                                                      numVertices); 
    
    //create a hull approximation 
    btShapeHull* hull = new btShapeHull(sshape); 
    btScalar margin = sshape->getMargin(); 
    hull->buildHull(margin); 
    sshape->setUserPointer(hull); 
    
    
    Isgl3dLog(Info,@"new numTriangles = %d\n", hull->numTriangles ()); 
    Isgl3dLog(Info,@"new numIndices = %d\n", hull->numIndices ()); 
    Isgl3dLog(Info,@"new numVertices = %d\n", hull->numVertices ()); 
    
    btConvexHullShape* convexShape = new btConvexHullShape(); 
    for (int i=0;i<hull->numVertices();i++) 
    { 
        convexShape->addPoint(hull->getVertexPointer()[i]); 
    } 
    
    delete sshape; 
    delete hull; 
    free(points); // release the dynamic array 
    
    collisionShape = convexShape; 
#endif 
    
    return collisionShape; 
} 





@end
