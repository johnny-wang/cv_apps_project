//
//  ViewController.h
//  GIS_info
//
//  Created by Johnny Wang on 11/28/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate> {
CLLocationManager *locationManager;
}

@end

