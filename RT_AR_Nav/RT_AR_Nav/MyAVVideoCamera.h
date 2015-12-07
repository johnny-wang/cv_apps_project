//
//  MyAVVideoCamera.h
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/6/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#ifndef MyAVVideoCamera_h
#define MyAVVideoCamera_h

#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#ifdef __cplusplus
#include <opencv2/core/core.hpp>
#endif

@class MyAVVideoCamera;

@protocol MyAVVideoCameraDelegate <NSObject>

#ifdef __cplusplus
- (void)processImage:(cv::Mat&)image;
#endif

@end

@interface MyAVVideoCamera : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession* captureSession;
    AVCaptureConnection* videoCaptureConnection;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    
    AVCaptureVideoDataOutput *videoDataOutput;
    dispatch_queue_t videoDataOutputQueue;
    
    UIDeviceOrientation currentDeviceOrientation;
    
    BOOL cameraAvailable;
    BOOL captureSessionLoaded;
    BOOL running;
    BOOL grayscaleMode;
    
    AVCaptureDevicePosition defaultAVCaptureDevicePosition;
    AVCaptureVideoOrientation defaultAVCaptureVideoOrientation;
    
    UIView* parentView;
}

@property (nonatomic, retain) AVCaptureSession* captureSession;
@property (nonatomic, retain) AVCaptureConnection* videoCaptureConnection;

@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) BOOL captureSessionLoaded;

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, assign) AVCaptureDevicePosition defaultAVCaptureDevicePosition;
@property (nonatomic, assign) AVCaptureVideoOrientation defaultAVCaptureVideoOrientation;

@property (nonatomic, retain) UIView* parentView;

@property (nonatomic, assign) id<MyAVVideoCameraDelegate> delegate;
@property (nonatomic, assign) BOOL grayscaleMode;

- (void)start;
- (void)stop;

- (id)initWithParentView:(UIView*)parent;

- (void)createVideoPreviewLayer;

@end

#endif /* MyAVVideoCamera_h */
