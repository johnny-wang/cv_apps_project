//
//  ViewController.m
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"  // this HAS TO come before homographyUtil

@interface ViewController () {    
    
    AVPlayerItem *playerItem_;
    AVPlayer *player_;
    
    UIImageView *imageView_;
    
    NSString *filePath_;
    NSURL *fileURL_;
    
    MyAVVideoCamera *videoCamera_;
    
    UILabel *fpsText;
    NSDate *lastFrameTime;
    CAShapeLayer *imageOverlay;
}

//@property (nonatomic, retain) MyAVVideoCamera* videoCamera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create and attach view so we can pass it to videoCamera
    imageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:imageView_];
    imageView_.contentMode = UIViewContentModeScaleAspectFit;
    
    videoCamera_ = [[MyAVVideoCamera alloc] initWithParentView:imageView_];
    videoCamera_.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera_.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera_.grayscaleMode = NO;
    videoCamera_.delegate = self;
 
    [videoCamera_ start];
    
//    [self addOverlay];

//    [self openVideo];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// main method to process the image and do tracking
- (void)processImage:(cv::Mat&)image {
    
}

- (void) addOverlay {
    imageOverlay=[CAShapeLayer layer];
    [self.view.layer addSublayer:imageOverlay];
}

- (void)openVideo {
    filePath_ = [[NSBundle mainBundle] pathForResource:@"section2" ofType:@"MOV"];
    fileURL_ = [NSURL fileURLWithPath:filePath_];
    player_ = [AVPlayer playerWithURL:fileURL_];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player_];
    player_.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    layer.frame = CGRectMake(0, 0, 1024, 768);
    [self.view.layer addSublayer: layer];
    
    [player_ play];
}

@end
