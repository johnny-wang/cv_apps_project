//
//  ViewController.m
//  RT_AR_Nav
//
//  Created by Johnny Wang on 12/1/15.
//  Copyright © 2015 CV_Apps. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    AVPlayer *player_;
    UIImageView *imageView_;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self playVideo];
    
//    [self loadVideo];
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
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    NSURL *fileURL = [NSURL fileURLWithPath:filepath];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    AVAssetImageGenerator *gen = [[AVAsseImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    
    imageView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:imageView_];
    imageView_.contentMode = UIViewContentModeScaleAspectFit;
    
    // Display 10 frames per second
    CMTime vid_length = asset.duration;
    float seconds = CMTimeGetSeconds(vid_length);
    
    int required_frames_count = seconds * 10;
    int64_t step = vid_length.value / required_frames_count;
    
    int value = 0;
    
    for (int i = 0; i < required_frames_count; i++) {
        
        AVAssetImageGenerator *image_generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        image_generator.requestedTimeToleranceAfter = kCMTimeZero;
        image_generator.requestedTimeToleranceBefore = kCMTimeZero;
        
        CMTime time = CMTimeMake(value, vid_length.timescale);
        
        CGImageRef image_ref = [image_generator copyCGImageAtTime:time actualTime:NULL error:NULL];
        UIImage *thumb = [UIImage imageWithCGImage:image_ref];
        CGImageRelease(image_ref);
        NSString *filename = [NSString stringWithFormat:@"frame_%d.png", i];
        NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:filename];
        
        [UIImagePNGRepresentation(thumb) writeToFile:pngPath atomically:YES];
        
        imageView_.image = thumb;
//        imageView_.image = [self processImage:thumb];
        
        value += step;
        
        NSLog(@"%d: %@", value, pngPath);
    }
}

@end
