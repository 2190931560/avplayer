//
//  LLoaderTask.h
//  avFoundation
//
//  Created by Ximmerse on 2018/3/12.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LoaderTaskRespone)(NSUInteger length);
typedef void (^LoaderTaskRcvData)(NSData *data);
typedef void (^LoaderTaskComplete)(NSError *error);

@interface LLoaderTask : NSObject
@property(nonatomic,assign)NSUInteger mCacheLength;//已经下载的长度
@property(nonatomic,assign)NSUInteger mVideoFileLength;//文件长度
@property(nonatomic,assign)NSUInteger mDownloadOffset;//从视频的 offset位置开始下载
@property(nonatomic,assign)BOOL mIsDownLoading;



-(void)startDownLoadWithURL:(NSURL*)url
                 fromOffset:(NSUInteger)offset
                  withRespone:(LoaderTaskRespone)responeBlock
                    rcvData:(LoaderTaskRcvData)revDataBlock
                   complete:(LoaderTaskComplete)completBlock;
-(void)cancelDownLoad;

@end
