//
//  ViewController.m
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"  // this HAS TO come before homographyUtil
#import <GPUImage/GPUImage.h>


@interface ViewController () {    
    GPUImageView *imageView_;
    AVPlayerItem *playerItem_;
    AVPlayer *player_;
    GPUImageMovie *movieFile_;
    GPUImageView *movieView_;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self playVideo];
    
    [self loadVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playVideo {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    self->player_ = [AVPlayer playerWithURL:fileURL];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self->player_];
    self->player_.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    layer.frame = CGRectMake(0, 0, 1024, 768);
    [self.view.layer addSublayer: layer];
    
    [self->player_ play];
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
    
    //    UIImage *currentImage = [movieFile_ imageFromCurrentFramebuffer];
    
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
    [cannyEdgeFilter addTarget:movieView_];
    
    /*
     [cannyEdgeFilter addTarget:lineFilter];
     [lineFilter addTarget:movieView_];
     
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
