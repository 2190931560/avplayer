//
//  SUFileHandle.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "SUFileHandle.h"

#define FILEPATH [[NSHomeDirectory( ) stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"1.mp4"]


@interface SUFileHandle ()

@property (nonatomic, strong) NSFileHandle * writeFileHandle;
@property (nonatomic, strong) NSFileHandle * readFileHandle;

@end

@implementation SUFileHandle

+ (BOOL)reCreateTempFile {
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * path = FILEPATH;
    if ([manager fileExistsAtPath:path]) {
        [manager removeItemAtPath:path error:nil];
    }
    return [manager createFileAtPath:path contents:nil attributes:nil];
}
+ (NSInteger)tmpFileLength{
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:FILEPATH]) {
        NSDictionary *attr = [manager attributesOfItemAtPath:FILEPATH error:nil];
        return [attr[NSFileSize] integerValue];
    }
    return 0;
}
+ (BOOL)createTempFile {
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * path = FILEPATH;
    if ([manager fileExistsAtPath:path]) {
        return true;
    }
    return [manager createFileAtPath:path contents:nil attributes:nil];
}
+ (void)writeTempFileData:(NSData *)data {
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:FILEPATH];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length {
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:FILEPATH];
    [handle seekToFileOffset:offset];
    return [handle readDataOfLength:length];
}


@end
