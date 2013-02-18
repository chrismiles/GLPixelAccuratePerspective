//
//  CMCenteredOpenGLView.m
//  GLPixelAccuratePerspective
//
//  Created by Chris Miles on 15/02/13.
//  Copyright (c) 2013 Chris Miles. All rights reserved.
//

#import "CMCenteredOpenGLView.h"


#undef __gl_h_
#import <GLKit/GLKit.h>


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#ifdef DEBUG
#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#define ASSERT_GL_OK() do {\
GLenum glError = glGetError();\
if (glError != GL_NO_ERROR) {\
ALog(@"glError: %d", glError);\
}} while (0)
#else
#define ASSERT_GL_OK() do { } while (0)
#endif


#define RectWidth 320
#define RectHeight 480
#define RectWidthf (RectWidth * 1.0f)
#define RectHeightf (RectHeight * 1.0f)


#define kRectVertexDataLength 30
static GLfloat rectVertexData[kRectVertexDataLength] =
{
    // posX, posY, posZ,    texcoordX, texcoordY
     1.0f/3.0f,   0.5f, 0.0f,	    1.0f, 1.0f,
    -1.0f/3.0f,   0.5f, 0.0f,	    0.0f, 1.0f,
     1.0f/3.0f,  -0.5f, 0.0f,	    1.0f, 0.0f,
     1.0f/3.0f,  -0.5f, 0.0f,	    1.0f, 0.0f,
    -1.0f/3.0f,   0.5f, 0.0f,	    0.0f, 1.0f,
    -1.0f/3.0f,  -0.5f, 0.0f,	    0.0f, 0.0f,
};



@interface CMCenteredOpenGLView ()
{
    GLKTextureInfo *_textureInfo;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

@property (strong) GLKBaseEffect *effect;

@end


@implementation CMCenteredOpenGLView

- (void)awakeFromNib
{
    [self prepareOpenGL];
}

- (void)dealloc
{
    [self tearDownScene];
}

- (void)prepareOpenGL
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFADepthSize, 32,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
	0
    };
    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    self.pixelFormat = pixelFormat;
    
    // Make this openGL context current to the thread
    // (i.e. all openGL on this thread calls will go to this context)
    [self.openGLContext makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [self.openGLContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    [self setUpScene];
}

- (void)setUpScene
{
    [self.openGLContext makeCurrentContext];
    
    NSString *imageFile = [[NSBundle mainBundle] pathForResource:@"sample_iphone_settings" ofType:@"png"];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    _textureInfo = [GLKTextureLoader textureWithContentsOfFile:imageFile options:options error:NULL];
    NSAssert(_textureInfo != nil, @"GLKTextureLoader failed");
    
    glBindTexture(GL_TEXTURE_2D, _textureInfo.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    ASSERT_GL_OK();

    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.name = _textureInfo.name;
    
    glGenVertexArrays(1, &_vertexArray);
    glBindVertexArray(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, kRectVertexDataLength*sizeof(GLfloat), rectVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), BUFFER_OFFSET(3*sizeof(GLfloat)));
    
    ASSERT_GL_OK();
}

- (void)tearDownScene
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArrays(1, &_vertexArray);
    
    self.effect = nil;
    
    ASSERT_GL_OK();
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.openGLContext makeCurrentContext];
    
    glViewport(dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height);
    
    {
	GLint viewPortData[4];
	glGetIntegerv(GL_VIEWPORT, viewPortData);
	NSRect viewPort = NSMakeRect(viewPortData[0], viewPortData[1], viewPortData[2], viewPortData[3]);
	NSLog(@"dirtyRect: %@ viewPort: %@", NSStringFromRect(dirtyRect), NSStringFromRect(viewPort));
    }
    
    GLKVector3 adjustment = GLKVector3Make(0.0f, 0.0f, 0.0f);
    if (fmod(dirtyRect.size.width, 2) != 0) adjustment.x += (0.5f * 1.0f/dirtyRect.size.width);
    if (fmod(dirtyRect.size.height, 2) != 0) adjustment.y += (0.5f * 1.0f/dirtyRect.size.height);
    
    float aspect = dirtyRect.size.width / dirtyRect.size.height;
    float fovy = GLKMathDegreesToRadians(25.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fovy, aspect, 0.1f, 100.0f);
    
    float zdist = 0.5f / tanf(fovy/2.0f);
    float scale = RectHeightf / dirtyRect.size.height;
    //GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -zdist);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(adjustment.x, adjustment.y, -zdist);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale, scale, scale);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    
    NSLog(@"scale: %f aspect: %f fovy: %f zdist: %f", scale, aspect, fovy, zdist);
    
    
    glClearColor(0.9f, 0.9f, 0.9f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, kRectVertexDataLength/3);
    
    ASSERT_GL_OK();
    
    glFlush();
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    
    ASSERT_GL_OK();
}

// TODO: Cocoa typically calls this method during scrolling and resize operations but may call it in other situations when the view's rectangles change. The default implementation does nothing. You can override this method if you need to adjust the viewport and display frustum.
//- (void)reshape
//{
//    
//}

@end
