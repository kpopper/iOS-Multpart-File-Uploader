//
//  MultiPartFileUploader.h
//  FieldNotes
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>

@class MultiPartFileUploader;

@protocol MultiPartFileUploaderDelegate <NSObject>
@optional
- (void)fileUploaderDidFailToUploadFile:(MultiPartFileUploader *)uploader;
- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPartNumber:(NSInteger)partNumber etag:(NSString *)etag;
@end


@interface MultiPartFileUploader : NSObject <AmazonServiceRequestDelegate>

@property (nonatomic, copy) NSString *s3Key;
@property (nonatomic, copy) NSString *s3Secret;
@property (nonatomic, copy) NSString *s3Bucket;
@property (nonatomic, assign) id<MultiPartFileUploaderDelegate> delegate;
@property (nonatomic, assign) NSURL *filePathUrl;
@property (nonatomic, retain) AmazonS3Client *s3;
@property (nonatomic, retain) S3CompleteMultipartUploadRequest *compReq;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSMutableSet *outstandingParts;

- (id)initWithS3Key:(NSString *)s3Key secret:(NSString *)s3Secret bucket:(NSString *)s3Bucket;

- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate;

@end
