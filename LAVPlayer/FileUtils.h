//
//  SUFileHandle.h
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileUtils : NSObject


+ (BOOL)createTempFile;

+ (BOOL)removeTempFile;

+ (BOOL)tempFileCompleteWithFileName:(NSString*)strURL;

+ (void)writeTempFileData:(NSData *)data;


+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

+ (NSInteger)tmpFileLength;

+(NSURL*)localURLFromRemoteURL:(NSString *)strURL;


@end
