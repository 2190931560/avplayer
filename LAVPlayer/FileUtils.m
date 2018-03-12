//
//  SUFileHandle.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "FileUtils.h"

#define FILEDIRECT [[NSHomeDirectory( ) stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"ltmp"]
#define FILEPATH   [[[NSHomeDirectory( ) stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"ltmp"] stringByAppendingPathComponent:@"file.tmp"]


@implementation FileUtils

+ (BOOL)removeTempFile {
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * path = FILEPATH;
    if ([manager fileExistsAtPath:path]) {
        return [manager removeItemAtPath:path error:nil];
    }
    return true;
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
    [manager createDirectoryAtPath:FILEDIRECT withIntermediateDirectories:YES attributes:nil error:nil];
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

+ (BOOL)tempFileCompleteWithFileName:(NSString*)strURL
{
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * path = FILEPATH;
    if ([manager fileExistsAtPath:path]) {
        strURL = [strURL stringByReplacingOccurrencesOfString:@"/" withString:@""];
        NSString* newPath = [FILEDIRECT stringByAppendingPathComponent:strURL.lowercaseString];NSLog(@"== %@",newPath);
        return [manager copyItemAtPath:FILEPATH toPath:newPath error:nil];
    }
    return NO;
}
+(NSURL*)localURLFromRemoteURL:(NSString *)strURL
{
    NSString *filePath = [strURL stringByReplacingOccurrencesOfString:@"/" withString:@""];
    filePath = [FILEDIRECT stringByAppendingPathComponent:filePath.lowercaseString];NSLog(@"-- %@",filePath);
    
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [NSURL fileURLWithPath:filePath];
    }
    return nil;
}

@end
