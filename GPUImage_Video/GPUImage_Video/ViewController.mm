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
    
    // For geolocation
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
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initLocation];
    
    [self loadVideo];
//    [self loadCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initLocation {
    geocoder = [[CLGeocoder alloc] init];
    
    if (locationManager == nil)
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = 20; // update after moving X meters
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        [locationManager startMonitoringSignificantLocationChanges];
        [locationManager startUpdatingLocation];
    }
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
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"section2" ofType:@"MOV"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    playerItem_ = [[AVPlayerItem alloc] initWithURL:fileURL];
    player_ = [AVPlayer playerWithPlayerItem:playerItem_];
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:playerItem_];
    
    movieFile_.runBenchmark = YES;
    movieFile_.playAtActualSpeed = YES;
    
    movieView_ = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    
    // Initialize filters
    GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    //    CGSize imgSize = currentImage.size;
    CGSize imgSize = CGSizeMake(1280, 720);
    NSLog(@"width = %f x height = %f", imgSize.width, imgSize.height); // 2048 x 1536
    float down_scale = 1.0;   // 0.17             // downscale of image
    
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
    [lineFilter setEdgeThreshold:0.5];
    [lineFilter setLineDetectionThreshold:0.5]; // 0.6
    
    // Try to find lines with only the bottom half of image
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 0.5, 0.5)];
    [movieFile_ addTarget:cropFilter];
    [cropFilter addTarget:lineFilter];

    /* Use just this to see all the Hough lines */
//    [movieFile_ addTarget:lineFilter];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 0.5;
//    [blendFilter forceProcessingAtSize:imgSize];

    [movieFile_ addTarget:blendFilter];
    
    // draw lines
    GPUImageLineGenerator *lineDrawFilter = [[GPUImageLineGenerator alloc] init];
//    [lineDrawFilter forceProcessingAtSize:imgSize];
    
    GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
    [lineGenerator forceProcessingAtSize:CGSizeMake(720.0, 1280.0)];
    [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
    
    [lineFilter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
        [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
        NSLog(@"lines detected: %ld", (unsigned long)linesDetected);
    }];
    [lineGenerator addTarget:blendFilter atTextureLocation:1];
    
    [blendFilter addTarget:movieView_];
    
    [self.view addSubview:movieView_];
    [self.view sendSubviewToBack:movieView_];
    
    player_.rate = 1.0;
    
    [movieFile_ startProcessing];
    
    [player_ play];
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
  
/*
    // visualization test
    CGPoint point;
    point.x = 100;
    point.y = 100;
    
    UIImage *inputImage = [UIImage imageNamed:@"forbes.jpg"];
    UIImage * ret_img;
*/
    
    NSString *addr = [NSString stringWithFormat: @"%@, %@, %@, %@, %@, %@ : %@, %@ ", name, thoroughfare, locality, state, country, postalCode, latitude, longitude];
    NSLog(@"%@", thoroughfare);
//    ret_img = [self drawText:addr inImage:inputImage atPoint:point];
    
//    imageView_.image = ret_img;
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

@end
