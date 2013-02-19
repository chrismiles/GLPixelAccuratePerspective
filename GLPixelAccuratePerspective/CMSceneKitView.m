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


@interface CMSceneKitView ()
@property (strong) SCNCamera *camera;
@property (strong) SCNNode *cameraNode;
@property (strong) SCNNode *planeNode;
@end


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
    [self setupScene];
}

- (void)setupScene
{
    //self.allowsCameraControl = YES;
    
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    
    self.camera = [SCNCamera camera];
    self.camera.zNear = 0.1;
    self.camera.zFar = 100.0;
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = self.camera;
    [scene.rootNode addChildNode:self.cameraNode];
    
    SCNPlane *plane = [SCNPlane planeWithWidth:(RectWidthf/RectHeightf) height:1.0f];
    plane.firstMaterial.diffuse.contents = [NSImage imageNamed:@"sample_iphone_settings"];
    plane.firstMaterial.diffuse.magnificationFilter = SCNNoFiltering;
    plane.firstMaterial.diffuse.minificationFilter = SCNNoFiltering;
    plane.firstMaterial.doubleSided = YES;
    
    self.planeNode = [SCNNode nodeWithGeometry:plane];
    [scene.rootNode addChildNode:self.planeNode];

    [self configureCameraWithViewSize:self.bounds.size];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self configureCameraWithViewSize:newSize];
}

- (void)configureCameraWithViewSize:(NSSize)viewSize
{
    CGFloat aspect = viewSize.width/viewSize.height;

    CGFloat yFov = 25.0;
    CGFloat zDist = 0.5 / tan((M_PI/180.0)*yFov/2.0);
    CGFloat xFov = (180.0/M_PI) * 2.0 * atan(0.5*aspect / zDist);
    
    CGPoint adjustment = CGPointZero;
    if (fmod(viewSize.width, 2) != 0) adjustment.x += (0.5f * 1.0f/viewSize.width);
    if (fmod(viewSize.height, 2) != 0) adjustment.y += (0.5f * 1.0f/viewSize.height);
    
    self.cameraNode.position = SCNVector3Make(adjustment.x, adjustment.y, zDist);
    
    self.camera.xFov = xFov;
    self.camera.yFov = yFov;
    
    CGFloat scale = RectHeightf / viewSize.height;
    self.planeNode.scale = SCNVector3Make(scale, scale, scale);
}

@end
