//
//  CMSceneKitView.m
//  GLPixelAccuratePerspective
//
//  Created by Chris Miles on 15/02/13.
//  Copyright (c) 2013 Chris Miles. All rights reserved.
//

#import "CMSceneKitView.h"

#define RectWidth 320
#define RectHeight 480
#define RectWidthf (RectWidth * 1.0f)
#define RectHeightf (RectHeight * 1.0f)


@implementation CMSceneKitView

- (id)initWithFrame:(NSRect)frameRect options:(NSDictionary *)options
{
    self = [super initWithFrame:frameRect options:options];
    if (self) {
	[self setupScene];
    }
    return self;
}

- (void)awakeFromNib
{
    // Need to delay enough for view size to be restored by AppKit.
    [self performSelector:@selector(setupScene) withObject:nil afterDelay:0.0];
}

- (void)setupScene
{
    self.allowsCameraControl = YES;
    
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    
    SCNCamera *camera = [SCNCamera camera];
    camera.zNear = 0.1;
    camera.zFar = 100.0;
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = camera;
    [scene.rootNode addChildNode:cameraNode];
    
    CGSize viewSize = self.bounds.size;
    CGFloat aspect = viewSize.width/viewSize.height;
    CGFloat scale = RectHeightf / viewSize.height;
    NSLog(@"View bounds: %@ aspect: %f scale: %f", NSStringFromRect(self.bounds), aspect, scale);
    
    SCNPlane *plane = [SCNPlane planeWithWidth:scale*(RectWidthf/RectHeightf) height:scale];
    plane.firstMaterial.diffuse.contents = [NSImage imageNamed:@"sample_iphone_settings"];
    plane.firstMaterial.diffuse.magnificationFilter = SCNNoFiltering;
    plane.firstMaterial.diffuse.minificationFilter = SCNNoFiltering;
    plane.firstMaterial.doubleSided = YES;
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    [scene.rootNode addChildNode:planeNode];
    
    CGFloat yFov = 25.0;
    CGFloat zDist = 0.5 / tan((M_PI/180.0)*yFov/2.0);
    CGFloat xFov = (180.0/M_PI) * 2.0 * atan(0.5*aspect / zDist);
    
    CGPoint adjustment = CGPointZero;
    if (fmod(viewSize.width, 2) != 0) adjustment.x += (0.5f * 1.0f/viewSize.width);
    if (fmod(viewSize.height, 2) != 0) adjustment.y += (0.5f * 1.0f/viewSize.height);

    //cameraNode.position = SCNVector3Make(0.0f, 0.0f, zDist);
    cameraNode.position = SCNVector3Make(adjustment.x, adjustment.y, zDist);
    
    camera.xFov = xFov;
    camera.yFov = yFov;
}

@end
