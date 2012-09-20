//
//  PartUploadTask.h
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 04/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPartDidFinishUploadingNotification @"PartDidFinishUploading"
#define kPartDidFailToUploadNotification @"PartDidFailToUpload"

@class AmazonS3Client, S3MultipartUpload;

@interface PartUploadTask : NSOperation

@property (nonatomic, assign) NSInteger partNumber;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) AmazonS3Client *s3;
@property (nonatomic, retain) S3MultipartUpload *upload;

- (id)initWithPartNumber:(NSInteger)partNumber dataToUpload:(NSData *)data s3Client:(AmazonS3Client *)s3 s3MultipartUpload:(S3MultipartUpload *)upload;

@end
