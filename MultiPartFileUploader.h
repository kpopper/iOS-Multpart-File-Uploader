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
- (void)fileUploaderDidFinishUploadingFile:(MultiPartFileUploader *)uploader;
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

/**
 Upload an entire file in chunks to the given S3 bucket
 @param filePathUrl The local path URL to the file in the phone's document store
 @param queue Your application's operation queue to be used to upload the files
 @param delegate An optional delegate to receive progress updates from the upload
 @returns YES if parts are successfully queued, NO if arguments are incorrect or there are problems connecting to S3
 */
- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate;

/**
 Upload an entire file in chunks to the given S3 bucket
 @param filePathUrl The local path URL to the file in the phone's document store
 @param outstandingParts A set of NSNumber objects with the parts that still need to be uploaded (1-based index)
 @param queue Your application's operation queue to be used to upload the files
 @param delegate An optional delegate to receive progress updates from the upload
 */
- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl outstandingParts:(NSSet *)outstandingParts operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate;

@end
