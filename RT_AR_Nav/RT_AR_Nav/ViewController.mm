//
//  ViewController.m
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#include "opencv2/opencv.hpp"

using namespace cv;

@interface ViewController () {
    
    /*** Setup the view fir video/camera ***/
    GPUImageView *imageView_;
    AVPlayerItem *playerItem_;
    AVPlayer *player_;
    GPUImageMovie *movieFile_;
    GPUImageView *movieView_;
    
    GPUImageView *filterView;
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    
    /*** For geolocation - to get road name ***/
    UIImage *street_name;
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    NSString *latitude;
    NSString *longitude;
    NSString *name; // eg. Apple Inc.
    NSString *thoroughfare; // street name, eg. Infinite Loop
    NSString *subThoroughfare; // eg. 1
    NSString *locality; // city, eg. Cupertino
    NSString *subLocality; // neighborhood, common name, eg. Mission District
    NSString *state; // state, eg. CA
    NSString *subAdministrativeArea; // county, eg. Santa Clara
    NSString *postalCode; // zip code, eg. 95014
    NSString *country; // eg. US
    NSString *inlandWater; // eg. Lake Tahoe
    NSString *ocean; // eg. Pacific Ocean
    
    /*** For road name projection ***/
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
    
    [self initLocation];
    [self initRoadName];
    
    [self loadVideo];
    //    [self loadCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initRoadName {
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
}

- (void)initLocation {
    geocoder = [[CLGeocoder alloc] init];
    
    if (locationManager == nil)
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = 10; // update after moving X meters
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        [locationManager startMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
        NSLog(@"initialized location manager");
    }
}

- (void)loadCamera {
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
    self.view = primaryView;
    
    filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(primaryView.frame.origin.x, primaryView.frame.origin.y, primaryView.frame.size.width, primaryView.frame.size.height)];
    [primaryView addSubview:filterView];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
//    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [blendFilter forceProcessingAtSize:CGSizeMake(1280.0, 768.0)];
    blendFilter.mix = 0.5;

    GPUImageHoughTransformLineDetector *lineFilter = [[GPUImageHoughTransformLineDetector alloc] init];
    [lineFilter setEdgeThreshold:0.9];
    [lineFilter setLineDetectionThreshold:0.6];
    
    GPUImageWhiteBalanceFilter *wbFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    wbFilter.temperature = 1000;
    
    [videoCamera addTarget:wbFilter];
    
    GPUImageHighlightShadowFilter *hsFilter = [[GPUImageHighlightShadowFilter alloc] init];
    hsFilter.shadows = 0.7;
    [wbFilter addTarget:hsFilter];
    [hsFilter addTarget:lineFilter];
    [videoCamera addTarget:blendFilter];
    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(1280.0, 768.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    
    [(GPUImageHoughTransformLineDetector *)lineFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        
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
                if((std::abs(lineArrayNew[0]-m_avg_)<1) && std::abs(lineArrayNew[1]-b_avg_)<0.3)
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
//        std::cout << m_avg_ << " " << b_avg_ << std::endl;
        
        [lineGenerator renderLinesFromArray:lineArrayNew count:1 frameTime:frameTime];
        
    }];
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
    
    blendFilter_name = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter_name.mix = 0.3;
    [blendFilter addTarget:blendFilter_name];
   
    [roadNamePic addTarget:blendFilter_name];
    [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,768)];
    [roadNamePic processImage];
    
    [blendFilter_name addTarget:filterView];
    
    [videoCamera startCameraCapture];
    videoCamera.runBenchmark = YES;
}

- (void)loadVideo {
//    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"section4_720" ofType:@"MOV"];
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"section5_long_720" ofType:@"MOV"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    playerItem_ = [[AVPlayerItem alloc] initWithURL:fileURL];
    player_ = [AVPlayer playerWithPlayerItem:playerItem_];
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:playerItem_];
    
//    movieFile_.runBenchmark = YES;
    movieFile_.playAtActualSpeed = YES;
    
    movieView_ = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    //    CGSize imgSize = currentImage.size;
    CGSize imgSize = CGSizeMake(1280, 768);
    NSLog(@"width = %f x height = %f", imgSize.width, imgSize.height); // 2048 x 1536
    float down_scale = 1.0;   // 0.17             // downscale of image
    
    // Set filter variables
    // scale/resize image
    GPUImageLanczosResamplingFilter *scaleFilter = [[GPUImageLanczosResamplingFilter alloc] init];
    float width_scale = imgSize.width * down_scale;
    float height_scale = imgSize.height * down_scale;
    NSLog(@"downscale: %f x %f", width_scale, height_scale);
    [scaleFilter forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(width_scale,height_scale)];
    
    GPUImageHoughTransformLineDetector *lineFilter = [[GPUImageHoughTransformLineDetector alloc] init];
    [lineFilter setEdgeThreshold:0.9];
    [lineFilter setLineDetectionThreshold:0.6]; // 0.6

/*
    // Try to find lines with only the bottom half of image
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 0.5, 0.5)];
    [movieFile_ addTarget:cropFilter];
    [cropFilter addTarget:lineFilter];
 */
    
    /* Use just this to see all the Hough lines */
    //    [movieFile_ addTarget:lineFilter];
    
    GPUImageWhiteBalanceFilter *wbFilter = [[GPUImageWhiteBalanceFilter alloc] init];
    wbFilter.temperature=1000;
    
    [movieFile_ addTarget:wbFilter];
    
    GPUImageHighlightShadowFilter *hsFilter = [[GPUImageHighlightShadowFilter alloc] init];
    hsFilter.shadows = 0.7;
    [wbFilter addTarget:hsFilter];
    [hsFilter addTarget:lineFilter];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 0.5;
    
    [movieFile_ addTarget:blendFilter];
    
    // draw lines
    GPUImageLineGenerator *lineDrawFilter = [[GPUImageLineGenerator alloc] init];
    //    [lineDrawFilter forceProcessingAtSize:imgSize];
    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(768.0, 1280.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    
    [lineFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        
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
                if((std::abs(lineArrayNew[0]-m_avg_)<1) && std::abs(lineArrayNew[1]-b_avg_)<0.3)
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
        
//        std::cout << m_avg_ << " " << b_avg_ << std::endl;
        
        [lineGenerator renderLinesFromArray:lineArray count:1 frameTime:frameTime];
//        NSLog(@"lines detected: %ld", (unsigned long)linesDetected);
    }];
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
    
    blendFilter_name = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter_name.mix = 0.3;
    [blendFilter addTarget:blendFilter_name];
    
    [roadNamePic addTarget:blendFilter_name];
    [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(width_scale,height_scale)];
    [roadNamePic processImage];
    
    [blendFilter_name addTarget:movieView_];
    
    [self.view addSubview:movieView_];
    [self.view sendSubviewToBack:movieView_];
    
    player_.rate = 1.0;
    
    [movieFile_ startProcessing];
    
    [player_ play];
}

-(void) _refresh
{
    NSString *road_name;

    if (thoroughfare == nil) {
        road_name = @"Forbes";
    } else {
        road_name = thoroughfare;
    }

    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:300], NSForegroundColorAttributeName: [UIColor whiteColor], NSBackgroundColorAttributeName: [UIColor clearColor]};
    
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
    if ((pts_to[0].x < pts_to[3].x) && (pts_to[0].y < pts_to[3].y))
    {
    
        vector<Point2f> pts_from={Point2f(0,0),Point2f(0,textImage.rows),Point2f(textImage.cols,0),Point2f(textImage.cols,textImage.rows)};
    
        Mat homography_mat = findHomography(pts_from,pts_to,0);
        textImage = [self cvMatFromUIImage:roadNameImage];
        warpPerspective(textImage,textImage,homography_mat,textImage.size() );
    
        roadNameImage=[self UIImageFromCVMat:textImage];
    
        if(ping_pong)
        {
            //roadNameImage = [self imageFromString:road_name attributes:attributes];
            roadNamePic1 = [[GPUImagePicture alloc] initWithImage:roadNameImage];
            [roadNamePic1 addTarget:blendFilter_name];
            [roadNamePic1 forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,768)];
            [roadNamePic1 processImage];
        }
        else
        {
            roadNamePic = [[GPUImagePicture alloc] initWithImage:roadNameImage];
            [roadNamePic addTarget:blendFilter_name];
            [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,768)];
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
     [roadNamePic forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1280,768)];
     [roadNamePic processImage];
     [movieFile_ startProcessing];*/
    //return pts_to;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    CLLocationCoordinate2D here = newLocation.coordinate;
    NSLog(@"%f %f ", here.latitude, here.longitude);
    
    // below is added 151204
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error == nil && ([placemarks count] > 0))
         {
             placemark = [placemarks lastObject];
             latitude = [NSString stringWithFormat:@"%.5f",newLocation.coordinate.latitude];
             longitude = [NSString stringWithFormat:@"%.5f",newLocation.coordinate.longitude];
             
             name = placemark.name;
             thoroughfare = placemark.thoroughfare;
             locality = placemark.locality;
             state = placemark.administrativeArea;
             country = placemark.country;
             postalCode = placemark.postalCode;
             
         } else
         {
             NSLog(@"loc bug %@", error.debugDescription);
         }
     }];
    
    NSString *addr = [NSString stringWithFormat: @"%@, %@, %@, %@, %@, %@ : %@, %@ ", name, thoroughfare, locality, state, country, postalCode, latitude, longitude];
    NSLog(@"%@", thoroughfare);
}

- (NSString *)getString
{
    return @"MOREWOOD";
}

- (UIImage*) drawText:(NSString*) text
              inImage:(UIImage*)  image
              atPoint:(CGPoint)   point
{
    
    UIFont *font = [UIFont boldSystemFontOfSize:12];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
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

@end
