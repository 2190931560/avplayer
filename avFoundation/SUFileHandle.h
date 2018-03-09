//
//  SUFileHandle.h
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUFileHandle : NSObject

/**
 *  创建临时文件
 */
+ (BOOL)createTempFile;
+ (BOOL)reCreateTempFile;

/**
 *  往临时文件写入数据
 */
+ (void)writeTempFileData:(NSData *)data;

/**
 *  读取临时文件数据
 */
+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

+ (NSInteger)tmpFileLength;

@end
