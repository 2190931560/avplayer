//
//  ViewController.m
//  avFoundation
//
//  Created by Ximmerse on 2018/3/7.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ViewController.h"
#import "SUFileHandle.h"

#define VIDEOURL1 @"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4"
#define VIDEOURL2 @"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
#define VIDEOURL3 @"http://192.168.9.28/1.mp4"
#define VIDEOURL4 @"http://download.lingyongqian.cn/music/AdagioSostenuto.mp3"

#define kCustomVideoScheme @"myScheme"
#define MimeType @"video/mp4"


@interface ViewController ()<AVAssetResourceLoaderDelegate,NSURLConnectionDataDelegate, NSURLSessionDataDelegate>{
    // NSFileHandle *fileHandle;
     NSMutableData *_tmpData;
}
@property(nonatomic,strong)AVPlayer *avPlayer;
@property(nonatomic,strong)AVPlayerLayer *playLayer;
@property (weak, nonatomic) IBOutlet UISlider *avSlider;
@property(nonatomic,assign)BOOL isReadToPlay;

@property(nonatomic,strong)NSURLSessionTask *task;
@property (nonatomic, strong) NSURLSession * session;              //会话对象

@property(nonatomic,strong)NSMutableArray *mRequests;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     [SUFileHandle createTempFile];
    // Do any additional setup after loading the view, typically from a nib.
    //AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:VIDEOURL2]];
     self.mRequests = [NSMutableArray array];

     NSURL *url = [NSURL URLWithString:VIDEOURL2];
     NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
     components.scheme = kCustomVideoScheme;
     AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:components.URL options:nil];
     [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
     AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
     
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
    self.playLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.playLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, 300);
    [self.view.layer addSublayer:self.playLayer];
    
     [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
     __weak typeof(self) weakSelf = self;
     [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
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



#pragma mark AVAssetResourceLoaderDelegate
static long long requestOffset = 0;
static long long cacheLength = 0;
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    // NSURL *resourceURL = loadingRequest.request.URL;
     [self.mRequests addObject:loadingRequest];
     @synchronized(self) {
          if (self.task) {
               if (loadingRequest.dataRequest.requestedOffset >= requestOffset &&
                   loadingRequest.dataRequest.requestedOffset <= requestOffset + cacheLength) {
                    NSLog(@"数据已经缓存，则直接完成 %ld",loadingRequest.dataRequest.requestedOffset);
                    
                    NSMutableArray * finishRequestList = [NSMutableArray array];
                    for (AVAssetResourceLoadingRequest * loadingRequest in self.mRequests) {
                         if ([self finishLoadingWithLoadingRequest:loadingRequest data:[NSData data]]) {
                              [finishRequestList addObject:loadingRequest];
                         }
                    }
                    [self.mRequests removeObjectsInArray:finishRequestList];
               }
          }else {
               requestOffset = loadingRequest.dataRequest.requestedOffset;
               NSLog(@"requestOffset = %ld",requestOffset);
               NSURL *resourceURL = loadingRequest.request.URL;
               NSURLComponents *components = [[NSURLComponents alloc] initWithURL:resourceURL resolvingAgainstBaseURL:NO];
               components.scheme = @"http";
              // NSLog(@"请求=%@",components.URL);
               NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:components.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
               NSString *strRange = [NSString stringWithFormat:@"bytes=%ld-%ld", 0, LONG_MAX];
               
               [request addValue:strRange forHTTPHeaderField:@"Range"];
             //  NSLog(@"%@",request);
               self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
               self.task = [self.session dataTaskWithRequest:request];
               [self.task resume];
          }
     }

     return YES;
     
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
     NSLog(@"==取消请求");
     [self.mRequests removeObject:loadingRequest];
}


#pragma mark - NSURLSessionDataDelegate
//服务器响应
static NSInteger fileLength = 0;

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
     completionHandler(NSURLSessionResponseAllow);
     NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
     NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
     NSString * fileLen = [[contentRange componentsSeparatedByString:@"/"] lastObject];
     fileLength = fileLen.integerValue > 0 ? fileLen.integerValue : response.expectedContentLength;
     NSLog(@"====== didReceiveResponse %ld",fileLength);
     
     [SUFileHandle reCreateTempFile];
}

//服务器返回数据 可能会调用多次

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // NSLog(@"======下载   dataLen = %ld",data.length);
     
     [SUFileHandle writeTempFileData:data];

     cacheLength += data.length;
     
     NSMutableArray * finishRequestList = [NSMutableArray array];
     for (AVAssetResourceLoadingRequest * loadingRequest in self.mRequests) {
          if ([self finishLoadingWithLoadingRequest:loadingRequest data:[NSData data]]) {
               [finishRequestList addObject:loadingRequest];
          }
     }
     [self.mRequests removeObjectsInArray:finishRequestList];
  
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
     NSLog(@"====== didCompleteWithError %@ %ld",error,_tmpData.length);

}

- (BOOL)finishLoadingWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest data:(NSData*)revData {
     //填充信息
     CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(MimeType), NULL);
     loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
     loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
     loadingRequest.contentInformationRequest.contentLength = fileLength;//file total length
     
     //读文件，填充数据
     NSUInteger requestedOffset111 = loadingRequest.dataRequest.requestedOffset;
     if (loadingRequest.dataRequest.currentOffset != 0) {
          requestedOffset111 = loadingRequest.dataRequest.currentOffset;
     }
     NSUInteger canReadLength = cacheLength - (requestedOffset111 - requestOffset);
     NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
     
     NSLog(@"requestOffset = %ld",loadingRequest.dataRequest.requestedOffset);

     [loadingRequest.dataRequest respondWithData:[SUFileHandle readTempFileDataWithOffset:requestedOffset111 - requestOffset length:respondLength]];
     //NSLog(@"%ld=============%ld=================",requestedOffset111 - requestOffset,respondLength);
     //如果完全响应了所需要的数据，则完成
     NSUInteger nowendOffset = requestedOffset111 + canReadLength;
     NSUInteger reqEndOffset = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
     if (nowendOffset >= reqEndOffset) {
          [loadingRequest finishLoading];
          NSLog(@"=============222222222=================");
          return YES;
     }
     return NO;
}

@end
