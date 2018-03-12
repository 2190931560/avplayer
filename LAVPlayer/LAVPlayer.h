//
//  LAVPlayer.h
//  avFoundation
//
//  Created by Ximmerse on 2018/3/12.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface LAVPlayer : AVPlayer
@property(nonatomic,strong)AVPlayerLayer *playerLayer;

- (LAVPlayer*)initWithURLString:(NSString*)urlString;

- (void)playWith:(NSString*)urlString;


@end
