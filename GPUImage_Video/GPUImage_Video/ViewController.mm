//
//  ViewController.m
//  GPUImage_Video
//
//  Created by Johnny Wang on 12/2/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#include "homographyUtil.hpp"
#include "opencv2/opencv.hpp"
#include <vector>
#include <cmath>
#include <queue>

using namespace cv;
using namespace std;

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
    
    UIImage *roadNameImage;
    GPUImagePicture *roadNamePic;
    GPUImagePicture *roadNamePic1;

    
    std::deque<float> m_value_;//(10);
    std::deque<float> b_value_;//(10);
    
    float m_avg_;
    float b_avg_;
    
    
    int recal_;
    vector<Point2f> pts_to;
   
    NSTimer *_updateTimer;
    
    Mat textImage;
    
    GPUImageAlphaBlendFilter *blendFilter_name;
    bool ping_pong;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSString *road_name =[self getString];
    NSDictionary *attributes = @{NSFontAttributeName            : [UIFont systemFontOfSize:300],
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSBackgroundColorAttributeName : [UIColor clearColor]};
    roadNameImage = [self imageFromString:road_name attributes:attributes];

    textImage = [self cvMatFromUIImage:roadNameImage];


    
    int width = textImage.cols;
    int height = textImage.rows;
    /* width/4 height*1/2 width*1/8 height*3/4 width*3/4 height*1/2 width*7/8 height*3/4 */
    
    pts_to={Point2f(width*3/8,height*3/4),Point2f(width*1/4,height*7/8),Point2f(width*5/8,height*3/4),Point2f(width*3/4,height*7/8)};
    
    
    vector<Point2f> pts_from={Point2f(0,0),Point2f(0,textImage.rows),Point2f(textImage.cols,0),Point2f(textImage.cols,textImage.rows)};
    Mat homography_mat = findHomography(pts_from,pts_to,0);
    
    
    warpPerspective(textImage,textImage,homography_mat,textImage.size() );

    roadNameImage=[self UIImageFromCVMat:textImage];
    
    roadNamePic = [[GPUImagePicture alloc] initWithImage:roadNameImage];
    
    _updateTimer = [NSTimer
                    scheduledTimerWithTimeInterval:1
                    target:self
                    selector:@selector(_refresh)
                    userInfo:self
                    repeats:YES
                    ];
    ping_pong=true;
    
    //[self loadVideo];
    [self loadCamera];
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
    videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [blendFilter forceProcessingAtSize:CGSizeMake(1280, 720)];
    blendFilter.mix = 0.5;
    
    
    
    GPUImageHoughTransformLineDetector *lineFilter = [[GPUImageHoughTransformLineDetector alloc] init];
    [lineFilter setEdgeThreshold:0.9];
    [lineFilter setLineDetectionThreshold:0.6]; // 0.6
    
    
    //[videoCamera addTarget:blendFilter];
    //[blendFilter addTarget:filterView];
    
    GPUImageWhiteBalanceFilter *wbFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    wbFilter.temperature=1000;
    
    [videoCamera addTarget:wbFilter];
    //[movieFile_ addTarget:lineFilter];
    
    GPUImageHighlightShadowFilter *hsFilter = [[GPUImageHighlightShadowFilter alloc] init];
    hsFilter.shadows = 0.7;
    [wbFilter addTarget:hsFilter];
    
    
    [hsFilter addTarget:lineFilter];


    [videoCamera addTarget:blendFilter];
    //[video addTarget:filterView];

    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(1280, 720)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    
    [(GPUImageHoughTransformLineDetector *)lineFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        
        
        //cout<<lineArray[0]<<endl;
        NSUInteger ind = 0;
        NSUInteger normalize_count = 0;
        GLfloat lineArrayNew[2];
        lineArrayNew[0]=0;
        lineArrayNew[1]=0;
        
        while(ind<2*linesDetected)
        {
            if ((lineArray[ind]<-0.5)&&(lineArray[ind]>-900))
            {
                lineArrayNew[0]+=lineArray[ind++];
                lineArrayNew[1]+=lineArray[ind++];
                normalize_count++;
            }
            else
                
            {
                ind+=2;
            }
        }
        lineArrayNew[0]/=(GLfloat)normalize_count;
        lineArrayNew[1]/=normalize_count;
        if(normalize_count!=0)
        {
            recal_=0;
            
            if (m_value_.size()<5)
            {
                m_value_.push_back(lineArrayNew[0]);
                b_value_.push_back(lineArrayNew[1]);
                
                for(size_t i=0; i<m_value_.size();++i)
                {
                    m_avg_+=m_value_[i];
                    b_avg_+=b_value_[i];
                }
                m_avg_/=m_value_.size();
                b_avg_/=b_value_.size();
            }
            else
            {
                if((abs(lineArrayNew[0]-m_avg_)<1)&&abs(lineArrayNew[1]-b_avg_)<0.3)
                {
                    m_value_.push_back(lineArrayNew[0]);
                    b_value_.push_back(lineArrayNew[1]);
                    m_value_.pop_front();
                    b_value_.pop_front();
                }
                
                for(size_t i=0; i<m_value_.size();++i)
                {
                    m_avg_+=m_value_[i];
                    b_avg_+=b_value_[i];
                }
                m_avg_/=m_value_.size();
                b_avg_/=b_value_.size();
                lineArrayNew[0]=m_avg_;
                lineArrayNew[1]=b_avg_;
                
                
            }
        }
        else
        {
            recal_++;
            if (recal_>=10)
            {
                m_value_.clear();
                b_value_.clear();
            }
        }
        //lineArrayNew[0]=10000;
        //lineArrayNew[1]=-0.5;
        
        cout<<m_avg_<<" "<<b_avg_<<endl;
        
        
        
        
        //if [normalize_count>0]
        [lineGenerator renderLinesFromArray:lineArrayNew count:1 frameTime:frameTime];
        //NSUInteger
    }];
    
    
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
    //[blendFilter addTarget:filterView];


    blendFilter_name = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter_name.mix = 0.3;
    [blendFilter addTarget:blendFilter_name];
    
    
    
    [roadNamePic addTarget:blendFilter_name];
    [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,720)];
    [roadNamePic processImage];
    
    
    
    
    
    
    
    [blendFilter_name addTarget:filterView];
    
    [videoCamera startCameraCapture];
    videoCamera.runBenchmark = YES;

}

- (void)loadVideo {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"section4_small" ofType:@"mov"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    playerItem_ = [[AVPlayerItem alloc] initWithURL:fileURL];
    player_ = [AVPlayer playerWithPlayerItem:playerItem_];
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:playerItem_];
    
    movieFile_.runBenchmark = YES;
    movieFile_.playAtActualSpeed = YES;
    
    movieView_ = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    // Initialize filters
    //GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    //    CGSize imgSize = currentImage.size;
    CGSize imgSize = CGSizeMake(1280, 720);
    NSLog(@"width = %f x height = %f", imgSize.width, imgSize.height); // 2048 x 1536
    float down_scale = 1;   // 0.17             // downscale of image
    
    // Set filter variables
    // scale/resize image
    GPUImageLanczosResamplingFilter *scaleFilter = [[GPUImageLanczosResamplingFilter alloc] init];
    float width_scale = imgSize.width * down_scale;
    float height_scale = imgSize.height * down_scale;
    NSLog(@"downscale: %f x %f", width_scale, height_scale);
    [scaleFilter forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(width_scale,height_scale)];

    

    
    // blur
    GPUImageGaussianBlurFilter *gausFilter = [[GPUImageGaussianBlurFilter alloc] init];
    float blur_radius = 1;  // 1                // Gaussian blur in pixels
    [gausFilter setBlurRadiusInPixels:blur_radius];
    
    GPUImageHoughTransformLineDetector *lineFilter = [[GPUImageHoughTransformLineDetector alloc] init];
    [lineFilter setEdgeThreshold:0.9];
    [lineFilter setLineDetectionThreshold:0.6]; // 0.6
    
    //GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 0.5, 0.5)];
    
     /* Scale down for better performance */
//    [movieFile_ addTarget:grayscaleFilter];
//    [grayscaleFilter addTarget:scaleFilter];
    
//    [movieFile_ addTarget:scaleFilter];
//    [scaleFilter addTarget:lineFilter];

    /* Is this cropping ?!?! */
//    [movieFile_ addTarget:cropFilter];
//    [cropFilter addTarget:lineFilter];

    /* Use just this to see all the Hough lines */
    GPUImageWhiteBalanceFilter *wbFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    wbFilter.temperature=1000;
    
    [movieFile_ addTarget:wbFilter];
    //[movieFile_ addTarget:lineFilter];
    
    GPUImageHighlightShadowFilter *hsFilter = [[GPUImageHighlightShadowFilter alloc] init];
    hsFilter.shadows = 0.7;
    [wbFilter addTarget:hsFilter];
    
    
    [hsFilter addTarget:lineFilter];

    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 0.5;
//    [blendFilter forceProcessingAtSize:imgSize];

    /**
    GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
    [movieFile_ addTarget:gammaFilter];
    [gammaFilter addTarget:blendFilter];
    **/
    [movieFile_ addTarget:blendFilter];
    

    
    
    
    // draw lines
    GPUImageLineGenerator *lineDrawFilter = [[GPUImageLineGenerator alloc] init];
//    [lineDrawFilter forceProcessingAtSize:imgSize];
   // [lineDrawFilter addTarget:blendFilter];
    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(720.0, 1280.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    
    [lineFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        
        
        //cout<<lineArray[0]<<endl;
        NSUInteger ind = 0;
        NSUInteger normalize_count = 0;
        GLfloat lineArrayNew[2];
        lineArrayNew[0]=0;
        lineArrayNew[1]=0;

        while(ind<2*linesDetected)
        {
            if ((lineArray[ind]<-0.5)&&(lineArray[ind]>-900))
            {
                lineArrayNew[0]+=lineArray[ind++];
                lineArrayNew[1]+=lineArray[ind++];
                normalize_count++;
            }
            else
                
            {
                ind+=2;
            }
        }
        lineArrayNew[0]/=(GLfloat)normalize_count;
        lineArrayNew[1]/=normalize_count;
        if(normalize_count!=0)
        {
            recal_=0;

            if (m_value_.size()<5)
            {
                m_value_.push_back(lineArrayNew[0]);
                b_value_.push_back(lineArrayNew[1]);
            
                for(size_t i=0; i<m_value_.size();++i)
                {
                    m_avg_+=m_value_[i];
                    b_avg_+=b_value_[i];
                }
                m_avg_/=m_value_.size();
                b_avg_/=b_value_.size();
            }
            else
            {
                if((abs(lineArrayNew[0]-m_avg_)<1)&&abs(lineArrayNew[1]-b_avg_)<0.3)
                {
                    m_value_.push_back(lineArrayNew[0]);
                    b_value_.push_back(lineArrayNew[1]);
                    m_value_.pop_front();
                    b_value_.pop_front();
                }

                for(size_t i=0; i<m_value_.size();++i)
                {
                    m_avg_+=m_value_[i];
                    b_avg_+=b_value_[i];
                }
                m_avg_/=m_value_.size();
                b_avg_/=b_value_.size();
                lineArrayNew[0]=m_avg_;
                lineArrayNew[1]=b_avg_;
            
        
            }
        }
        else
        {
            recal_++;
            if (recal_>=10)
            {
                m_value_.clear();
                b_value_.clear();
            }
        }
        //lineArrayNew[0]=10000;
        //lineArrayNew[1]=-0.5;
        
        cout<<m_avg_<<" "<<b_avg_<<endl;
        
        
        
        
        //if [normalize_count>0]
        [lineGenerator renderLinesFromArray:lineArrayNew count:1 frameTime:frameTime];
        NSLog(@"lines detected: %çld", (unsigned long)linesDetected);
        
        //NSUInteger
        
    }];
    //cout<<lineFilter->rawImagePixels<<endl;
    
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
   // GPUImagePicture *roadNamePic = [[GPUImagePicture alloc] initWithImage:roadNameImage];
    
    
    blendFilter_name = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter_name.mix = 0.3;
    [blendFilter addTarget:blendFilter_name];
    
    
    
    [roadNamePic addTarget:blendFilter_name];
    [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(width_scale,height_scale)];
    [roadNamePic processImage];
    
    
    
    
    
    
    
    [blendFilter_name addTarget:movieView_];
    
    
    
    
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
    //[roadNamePic processImage];

    [movieFile_ startProcessing];
    [player_ play];
}


-(void) _refresh
{
//={Point2f(width*3/8,height*3/4),Point2f(width*1/4,height*7/8),Point2f(width*5/8,height*3/4),Point2f(width*3/4,height*7/8)};
    NSString *road_name =@"Forbes";
    NSDictionary *attributes = @{NSFontAttributeName            : [UIFont systemFontOfSize:300],
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSBackgroundColorAttributeName : [UIColor clearColor]};
    
    
    roadNameImage = [self imageFromString:road_name attributes:attributes];
    pts_to.clear();
    Point2f pt_tmp;
    
    
    double rows = textImage.rows;
    double cols = textImage.cols;
    
    pt_tmp.x = ((0.5-b_avg_)/m_avg_+1)/2*cols;
    pt_tmp.y = (0.5+1)/2*rows;
    pts_to.push_back(pt_tmp);
    
    pt_tmp.x = ((0.75-b_avg_)/m_avg_+1)/2*cols;
    pt_tmp.y = (0.75+1)/2*rows;
    pts_to.push_back(pt_tmp);
    
    pt_tmp.x = ((0.5-b_avg_)/(-m_avg_)+1)/2*cols;
    pt_tmp.y = (0.5+1)/2*rows;
    pts_to.push_back(pt_tmp);
    
    pt_tmp.x = ((0.75-b_avg_)/(-m_avg_)+1)/2*cols;
    pt_tmp.y = (0.75+1)/2*rows;
    pts_to.push_back(pt_tmp);
    if ((pts_to[0].x<pts_to[3].x)&&(pts_to[0].y<pts_to[3].y))
    {
        
    //cout<<pts_to[0].x<<" "<<pts_to[0].y<<endl;
    //cout<<pts_to[1].x<<" "<<pts_to[1].y<<endl;
    //cout<<pts_to[2].x<<" "<<pts_to[2].y<<endl;
    //cout<<pts_to[3].x<<" "<<pts_to[3].y<<endl;

    
    
    vector<Point2f> pts_from={Point2f(0,0),Point2f(0,textImage.rows),Point2f(textImage.cols,0),Point2f(textImage.cols,textImage.rows)};
    
    
    Mat homography_mat = findHomography(pts_from,pts_to,0);
    textImage = [self cvMatFromUIImage:roadNameImage];

    warpPerspective(textImage,textImage,homography_mat,textImage.size() );
    roadNameImage=[self UIImageFromCVMat:textImage];
    if(ping_pong)
    {

    
    roadNamePic1 = [[GPUImagePicture alloc] initWithImage:roadNameImage];
    [roadNamePic1 addTarget:blendFilter_name];
    [roadNamePic1 forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,720)];
    [roadNamePic1 processImage];
    }
    else
    {
        /*
        NSString *road_name =@"Forbes";
        NSDictionary *attributes = @{NSFontAttributeName            : [UIFont systemFontOfSize:300],
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSBackgroundColorAttributeName : [UIColor clearColor]};
        
        
        roadNameImage = [self imageFromString:road_name attributes:attributes];
        Mat homography_mat = findHomography(pts_from,pts_to,0);
        textImage = [self cvMatFromUIImage:roadNameImage];

        warpPerspective(textImage,textImage,homography_mat,textImage.size() );
        
        roadNameImage=[self UIImageFromCVMat:textImage];
        */
        roadNamePic = [[GPUImagePicture alloc] initWithImage:roadNameImage];
        [roadNamePic addTarget:blendFilter_name];
        [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,720)];
        [roadNamePic processImage];
        
    }
    
    ping_pong = !ping_pong;
    }
    
/*
    warpPerspective(textImage,textImage,homography_mat,textImage.size() );
    
    roadNameImage=[self UIImageFromCVMat:textImage];
    
    blendFilter_name = [[GPUImageAlphaBlendFilter alloc] init];
    */
    //blendFilter_name.mix += 0.1;
    /*
    roadNamePic = [[GPUImagePicture alloc] initWithImage:roadNameImage];
    [roadNamePic addTarget:blendFilter_name];
    [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,720)];
    [roadNamePic processImage];
    [movieFile_ startProcessing];*/
    //return pts_to;
}


- (NSString *)getString
{
    return @"MOREWOOD";
}

- (UIImage *)imageFromString:(NSString *)string attributes:(NSDictionary *)attributes
{
    // function to convert string to image
    CGSize maximumLabelSize = CGSizeMake(9999, 9999);
    CGRect textRect = [string boundingRectWithSize:maximumLabelSize
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes
                                           context:nil];
    
    UIGraphicsBeginImageContextWithOptions(textRect.size, NO, 0);
    
    [string drawInRect:textRect withAttributes:attributes];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


// Member functions for converting from UIImage to cvMat
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
