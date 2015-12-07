//
//  ViewController.h
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "MyAVVideoCamera.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#include "opencv2/highgui/cap_ios.h"
#include "opencv2/opencv.hpp"
#include "homographyUtil.hpp"

@interface ViewController : UIViewController<MyAVVideoCameraDelegate>


@end

