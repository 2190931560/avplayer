//
//  LLoaderTask.m
//  avFoundation
//
//  Created by Ximmerse on 2018/3/12.
//  Copyright © 2018年 Ximmerse. All rights reserved.
//

#import "LLoaderTask.h"
#import "FileUtils.h"

@interface LLoaderTask()<NSURLSessionDelegate>

@property(nonatomic,strong)NSURLSession         *mSession;
@property(nonatomic,strong)NSURLSessionDataTask *mTask;
@property(nonatomic,assign)BOOL                  mIsCache;
@property(nonatomic,copy)  LoaderTaskRespone      mBlockRespone;
@property(nonatomic,copy)  LoaderTaskRcvData      mBlockRcvData;
@property(nonatomic,copy)  LoaderTaskComplete      mBlockComplete;
@property(nonatomic,copy) NSString * mStrFileURL;
@end

@implementation LLoaderTask

-(id)init
{
    self = [super init];
    if(self){
        _mIsDownLoading = NO;
    }
    
    return self;
}
-(void)startDownLoadWithURL:(NSURL*)url
                 fromOffset:(NSUInteger)offset
                withRespone:(LoaderTaskRespone)responeBlock
                    rcvData:(LoaderTaskRcvData)revDataBlock
                   complete:(LoaderTaskComplete)completBlock
{
    [self cancelDownLoad];
    self.mCacheLength = 0;
    //
    self.mStrFileURL = url.absoluteString;
    self.mDownloadOffset = offset;
    self.mIsCache = offset>0?NO:YES;
    
    self.mBlockRespone = responeBlock;
    self.mBlockRcvData = revDataBlock;
    self.mBlockComplete = completBlock;
    
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
    NSString *strRange = [NSString stringWithFormat:@"bytes=%ld-%ld", offset, LONG_MAX];
    [request addValue:strRange forHTTPHeaderField:@"Range"];
    //  NSLog(@"%@",request);
    self.mSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.mTask = [self.mSession dataTaskWithRequest:request];
    [self.mTask resume];
    
    self.mIsDownLoading = YES;
}
-(void)cancelDownLoad
{
    if(self.mTask){
        [self.mSession invalidateAndCancel];
        [self.mTask cancel];
        self.mSession = nil;
        self.mTask = nil;
    }
    self.mBlockRespone = nil;
    self.mBlockRcvData = nil;
    self.mBlockComplete = nil;
    self.mIsDownLoading = NO;
}



#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLen = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.mVideoFileLength = fileLen.integerValue > 0 ? fileLen.integerValue : response.expectedContentLength;
    NSLog(@"====== didReceiveResponse %ld",self.mVideoFileLength);
    
    [FileUtils removeTempFile];
    [FileUtils createTempFile];
    
    if(self.mBlockRespone)
        self.mBlockRespone(self.mVideoFileLength);
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
   // NSLog(@"======下载   dataLen = %ld",data.length);
    
    [FileUtils writeTempFileData:data];
    self.mCacheLength += data.length;
    
    if(self.mBlockRcvData)
        self.mBlockRcvData(data);
    
    
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"====== didCompleteWithError %@ %ld",error,self.mCacheLength);
    //表示下载了完整的
    self.mIsDownLoading = NO;
    
    if(self.mDownloadOffset == 0)
        [FileUtils tempFileCompleteWithFileName:self.mStrFileURL];
    
    if(self.mBlockComplete)
        self.mBlockComplete(error);
}

@end
