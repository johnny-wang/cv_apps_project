//
//  ViewController.m
//  This file is for testing the homography estimation, road name generation and road name projection
//
//  Created by Yuhan Long on 11/22/15.
//  Copyright © 2015 Yuhan Long. All rights reserved.
//

#include "opencv2/opencv.hpp"
#import "ViewController.h"
#include "homographyUtil.hpp"


using namespace cv;
using namespace std;

@interface ViewController () {
    UIImageView *imageView_;
    NSString *road_name;
}

@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /** read the test image */
    UIImage *inputImage = [UIImage imageNamed:@"forbes.jpg"];
    Mat roadImage = [self cvMatFromUIImage:inputImage];
    
    /** convert the road name to a image */
    Mat textImage = cvMatFromString_cv("FORBES");
    
    /** Initialize road name boundary points */
    /** [TODO] Automate this */
    vector<Point2f> pts_from={Point2f(0,0),Point2f(0,textImage.rows),Point2f(textImage.cols,0),Point2f(textImage.cols,textImage.rows)};
    vector<Point2f> pts_to={Point2f(500,456),Point2f(392,522),Point2f(805,450),Point2f(840,517)};
    
    /** Find homography */
    Mat H;
    fitHomography(pts_from, pts_to, H);
    cout<<H<<endl;

    /** Project the warped road name */
    Mat resultImage;
    projHomography(roadImage, textImage, resultImage, H);
    
    
    /** Display the image */
    imageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:imageView_];
    imageView_.contentMode = UIViewContentModeScaleAspectFit;

    imageView_.image = [self UIImageFromCVMat:resultImage];
}



- (cv::Mat)cvMatFromString:(NSString *)text
{
    /** This function is for convering the text into the cvMat format 
     * There is probably a better solution to use opencv put text function
     * Not used in current code
     */
    Mat stringImage;
    return stringImage;
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
