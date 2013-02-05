//
//  PartUploadTask.h
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 04/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>

@class AmazonS3Client, S3MultipartUpload, PartUploadTask;

@protocol PartUploadTaskDelegate <NSObject>
- (void)partUploadTaskDidFail:(PartUploadTask *)task;
@optional
- (void)partUploadTaskDidBegin:(PartUploadTask *)task;
- (void)partUploadTask:(PartUploadTask *)task didUploadPercentage:(float)progress;
- (void)partUploadTask:(PartUploadTask *)task didFinishUploadingPartNumber:(NSInteger)partNumber etag:(NSString *)etag;
@end

@interface PartUploadTask : NSOperation <AmazonServiceRequestDelegate>
{
    BOOL isExecuting;
    BOOL isFinished;
}

@property (nonatomic, strong) id<PartUploadTaskDelegate> delegate;
@property (nonatomic, assign) NSInteger partNumber;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) AmazonS3Client *s3;
@property (nonatomic, strong) S3MultipartUpload *upload;
@property (nonatomic, assign) float percentageUploaded;

- (id)initWithPartNumber:(NSInteger)partNumber dataToUpload:(NSData *)data s3Client:(AmazonS3Client *)s3 s3MultipartUpload:(S3MultipartUpload *)upload;

@end
