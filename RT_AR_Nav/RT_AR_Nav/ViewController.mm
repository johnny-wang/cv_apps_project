//
//  ViewController.m
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    AVPlayer *_player;
    UIImageView *imageView_;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self playVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playVideo {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    self->_player = [AVPlayer playerWithURL:fileURL];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self->_player];
    self->_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    layer.frame = CGRectMake(0, 0, 1024, 768);
    [self.view.layer addSublayer: layer];
    
    [self->_player play];
}

@end
