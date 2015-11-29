//
//  ViewController.m
//  GIS_info
//
//  Created by Johnny Wang on 11/28/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    CLGeocoder *geocoder;
    CLGeocoder *placemark;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [super viewDidLoad];
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    self->player = [AVPlayer playerWithURL:fileURL];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self->player];
    self->player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    layer.frame = CGRectMake(0, 0, 1024, 768);
    [self.view.layer addSublayer: layer];
    
    [self->player play];
    
/*
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
*/
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    CLLocationCoordinate2D here = newLocation.coordinate;
    NSLog(@"%f %f ", here.latitude, here.longitude);
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed %ld", (long)[error code]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
