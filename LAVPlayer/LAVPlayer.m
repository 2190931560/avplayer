//
//  LAVPlayer.m
//  avFoundation
//
//  Created by Ximmerse on 2018/3/12.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//

#define kCustomVideoScheme @"LAVPlyerScheme"
#define MimeType @"video/mp4"

#import <MobileCoreServices/MobileCoreServices.h>

#import "LAVPlayer.h"
#import "LLoaderTask.h"
#import "FileUtils.h"


@interface LAVPlayer()<AVAssetResourceLoaderDelegate>
@property(nonatomic,strong)NSMutableArray *mRequests;
@property(nonatomic,strong)LLoaderTask    *mLoaderTask;
@property(nonatomic,assign)BOOL mIsSeeking;

@end

@implementation LAVPlayer

- (LAVPlayer*)init
{
    self = [super init];
    if(self){
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self];
    }
    
    return self;
}
- (LAVPlayer*)initWithURLString:(NSString*)urlString
{
    self = [super init];
    if(self){
        [self playWith:urlString];
    }
    
    return self;
}

- (void)playWith:(NSString*)urlString
{
   
    self.mIsSeeking = NO;
    self.mRequests = [NSMutableArray array];
    NSURL *localURL = [FileUtils localURLFromRemoteURL:urlString];
    if(localURL){//有缓存文件
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:localURL options:nil];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        [self replaceCurrentItemWithPlayerItem:item];
    }else{//没有存文件
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        components.scheme = kCustomVideoScheme;
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:components.URL options:nil];
        [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        [self replaceCurrentItemWithPlayerItem:item];
    }
}


-(void)startDownLoad:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSUInteger offset = loadingRequest.dataRequest.requestedOffset;
    NSURL *resourceURL = loadingRequest.request.URL;
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:resourceURL resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    // NSLog(@"请求=%@",components.URL);
    self.mLoaderTask = [[LLoaderTask alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.mLoaderTask startDownLoadWithURL:components.URL fromOffset:offset withRespone:^(NSUInteger length) {
        
    } rcvData:^(NSData *data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (AVAssetResourceLoadingRequest * loadingRequest in strongSelf.mRequests) {
            if ([strongSelf processLoadingRequest:loadingRequest]) {
                [strongSelf.mRequests removeObject:loadingRequest];
            }
        }
        
    } complete:^(NSError *error) {
       // __strong typeof(weakSelf) strongSelf = weakSelf;
        
    }];
    self.mIsSeeking = NO;
}


#pragma mark AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    // NSURL *resourceURL = loadingRequest.request.URL;
    [self.mRequests addObject:loadingRequest];
    @synchronized(self) {
        if (self.mLoaderTask) {
            //loadingRequest 请求的数据已经下载完成
            if (loadingRequest.dataRequest.requestedOffset >= self.mLoaderTask.mDownloadOffset &&
                loadingRequest.dataRequest.requestedOffset <= self.mLoaderTask.mDownloadOffset + self.mLoaderTask.mCacheLength) {
                
                for (AVAssetResourceLoadingRequest * loadingRequest in self.mRequests) {
                    if ([self processLoadingRequest:loadingRequest]) {
                        [self.mRequests removeObject:loadingRequest];
                    }
                }
            }else if(self.mIsSeeking){
                [self startDownLoad:loadingRequest];
            }
            
        }else {
            
            [self startDownLoad:loadingRequest];
        }
    }
    
    return YES;
    
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"didCancelLoadingRequest");
    [self.mRequests removeObject:loadingRequest];
}

#pragma mark process resourceLoader's request data
- (BOOL)processLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    //填充信息
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(MimeType), NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.mLoaderTask.mVideoFileLength;//file total length
    
    //读文件，填充数据
    NSUInteger requestOffset = loadingRequest.dataRequest.requestedOffset;
    //NSLog(@"requestOffset = %lld current = %lld request = %ld",loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.currentOffset,loadingRequest.dataRequest.requestedLength);

    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestOffset = loadingRequest.dataRequest.currentOffset;
    }
    //从请求起始点开始的长度
    NSUInteger canReadLength = self.mLoaderTask.mCacheLength - (requestOffset - self.mLoaderTask.mDownloadOffset);
    //回复的长度
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    //NSLog(@"requestOffset = %lld",loadingRequest.dataRequest.requestedOffset);
    //从缓存文件中读取需要填充的数据
    [loadingRequest.dataRequest respondWithData:[FileUtils readTempFileDataWithOffset:requestOffset - self.mLoaderTask.mDownloadOffset length:respondLength]];
    //如果完全响应了所需要的数据，则完成
    NSUInteger nowEndOffset = requestOffset + canReadLength;
    NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
    if (nowEndOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}

@end
