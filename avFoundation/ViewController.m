//
//  ViewController.m
//  avFoundation
//
//  Created by Ximmerse on 2018/3/7.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "LAVPlayer.h"

#define VIDEOURL1 @"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4"
#define VIDEOURL2 @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
#define VIDEOURL3 @"http://192.168.9.28/1.mp4"
#define VIDEOURL4 @"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3"



@interface ViewController ()<AVAssetResourceLoaderDelegate,NSURLConnectionDataDelegate, NSURLSessionDataDelegate>{
    // NSFileHandle *fileHandle;
     NSMutableData *_tmpData;
}
@property(nonatomic,strong)LAVPlayer *avPlayer;
@property (weak, nonatomic) IBOutlet UISlider *avSlider;
@property(nonatomic,assign)BOOL isReadToPlay;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
     
     
    self.avPlayer = [[LAVPlayer alloc] initWithURLString:VIDEOURL2];
    self.avPlayer.playerLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, 300);
    [self.view.layer addSublayer:self.avPlayer.playerLayer];
    
     [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
     __weak typeof(self) weakSelf = self;
     [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
          AVPlayerItem *item = weakSelf.avPlayer.currentItem;
          weakSelf.avSlider.value = item.currentTime.value/ item.currentTime.timescale;
     }];
    
     
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:
(NSDictionary<NSString *,id> *)change context:(void *)context{
     if ([keyPath isEqualToString:@"status"]) {
          //取出status的新值
          AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] intValue];
          switch (status) {
               case AVPlayerItemStatusFailed:
                    NSLog(@"item 有误 %@",change);
                    self.isReadToPlay = NO;
                    break;
               case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"准好播放了");
                    self.isReadToPlay = YES;
                    self.avSlider.maximumValue = self.avPlayer.currentItem.duration.value / self.avPlayer.currentItem.duration.timescale;
                    [self.avPlayer play];
                    break;
               case AVPlayerItemStatusUnknown:
                    NSLog(@"视频资源出现未知错误");
                    self.isReadToPlay = NO;
                    break;
               default:
                    NSLog(@"default");
                    break;
          }
     }
     //移除监听（观察者）
     [object removeObserver:self forKeyPath:@"status"];
}

@end
