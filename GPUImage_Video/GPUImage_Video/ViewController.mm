//
//  ViewController.m
//  GPUImage_Video
//
//  Created by Johnny Wang on 12/2/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>

@interface ViewController () {
    // Setup the view
    GPUImageView *imageView_;
    AVPlayerItem *playerItem_;
    AVPlayer *player_;
    GPUImageMovie *movieFile_;
    GPUImageView *movieView_;
    
    GPUImageView *filterView;
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    __unsafe_unretained UISlider *slider;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self loadVideo];
//    [self loadCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadCamera {
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
//    primaryView.backgroundColor = [UIColor blueColor];
    self.view = primaryView;
  
    filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(primaryView.frame.origin.x, primaryView.frame.origin.y, primaryView.frame.size.width, primaryView.frame.size.height)];
    [primaryView addSubview:filterView];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [blendFilter forceProcessingAtSize:CGSizeMake(720.0, 1280.0)];
    blendFilter.mix = 0.5;
    [videoCamera addTarget:blendFilter];
    [blendFilter addTarget:filterView];
    
    filter = [[GPUImageHoughTransformLineDetector alloc] init];
    [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:0.60];
    [videoCamera addTarget:filter];

    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [filter addTarget:gammaFilter];
    [gammaFilter addTarget:blendFilter atTextureLocation:0];

    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(720.0, 1280.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    [(GPUImageHoughTransformLineDetector *)filter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
    }];
    [lineGenerator addTarget:blendFilter atTextureLocation:1];

    [videoCamera startCameraCapture];
    videoCamera.runBenchmark = YES;

}

- (void)loadVideo {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"test_whole" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    playerItem_ = [[AVPlayerItem alloc] initWithURL:fileURL];
    player_ = [AVPlayer playerWithPlayerItem:playerItem_];
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:playerItem_];
    
    movieFile_.runBenchmark = YES;
    movieFile_.playAtActualSpeed = YES;
    
    movieView_ = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    // Initialize filters
    GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    GPUImageLanczosResamplingFilter *scaleFilter = [[GPUImageLanczosResamplingFilter alloc] init];
    GPUImageGaussianBlurFilter *gausFilter = [[GPUImageGaussianBlurFilter alloc] init];
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    GPUImageHoughTransformLineDetector *lineFilter = [[GPUImageHoughTransformLineDetector alloc] init];
    // draw lines
    GPUImageLineGenerator *lineDrawFilter = [[GPUImageLineGenerator alloc] init];
    
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    
    //    CGSize imgSize = currentImage.size;
    CGSize imgSize = CGSizeMake(1280, 720);
    NSLog(@"width = %f, height = %f", imgSize.width, imgSize.height); // 2448 x 3264
    float down_scale = 0.15;   // 0.17             // downscale of image
    float blur_radius = 1;  // 1                // Gaussian blur in pixels
    float lower_thresh = 0.1; // 0.11             // cannyEdge lower threshold
    float upper_thresh = lower_thresh * 3;  // cannyEdge upper threshold
    float line_thresh = 0.10;  //0.6             // hough line threshold
    
    float width_scale = imgSize.width * down_scale;
    float height_scale = imgSize.height * down_scale;
    
    // Set filter variables
    // scale/resize image
    [scaleFilter forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(width_scale,height_scale)];
    // blur
    [gausFilter setBlurRadiusInPixels:blur_radius];
    [cannyEdgeFilter setBlurRadiusInPixels:blur_radius];
    [cannyEdgeFilter setLowerThreshold:lower_thresh];
    [cannyEdgeFilter setUpperThreshold:upper_thresh];
    [lineFilter setLineDetectionThreshold:line_thresh];
    [lineDrawFilter forceProcessingAtSize:imgSize];
    
    [movieFile_ addTarget:grayscaleFilter];
    [grayscaleFilter addTarget:scaleFilter];
    [scaleFilter addTarget:gausFilter];
    [gausFilter addTarget:cannyEdgeFilter];
    [cannyEdgeFilter addTarget:lineFilter];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 0.5;
    [blendFilter forceProcessingAtSize:imgSize];
    
    [movieFile_ addTarget:gammaFilter];
    [gammaFilter addTarget:blendFilter];
    
    [lineFilter addTarget:blendFilter];
    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(720.0, 1280.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    [(GPUImageHoughTransformLineDetector *)filter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
        NSLog(@"lines detected: %ld", (unsigned long)linesDetected);
    }];
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
    
    [blendFilter addTarget:movieView_];
    
    /*
     __weak typeof(self) weakSelf = self;
     [lineFilter setLinesDetectedBlock:^(GLfloat *flt, NSUInteger count, CMTime time) {
     NSLog(@"Number of lines: %ld", (unsigned long)count);
     GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
     [blendFilter forceProcessingAtSize:imgSize];
     [movieFile_ addTarget:blendFilter];
     [lineDrawFilter addTarget:blendFilter];
     
     [blendFilter useNextFrameForImageCapture];
     [lineDrawFilter renderLinesFromArray:flt count:count frameTime:time];
     //        weakSelf.doneProcessingImage([blendFilter imageFromCurrentFramebuffer]);
     }];
     */
    
    [self.view addSubview:movieView_];
    [self.view sendSubviewToBack:movieView_];
    
    player_.rate = 1.0;
    
    [movieFile_ startProcessing];
    
    [player_ play];
}

@end
