//
//  MultiPartFileUploader.h
//  FieldNotes
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PartUploadTask.h"
#import <AWSiOSSDK/S3/AmazonS3Client.h>

@class MultiPartFileUploader;

@protocol MultiPartFileUploaderDelegate <NSObject>
@optional
- (void)fileUploaderDidFailToUploadFile:(MultiPartFileUploader *)uploader;
- (void)fileUploader:(MultiPartFileUploader *)uploader didStartUploadingFileWithNumberOfParts:(NSInteger)numberOfParts;
- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPercentage:(float)percentage ofPartNumber:(NSInteger)partNumber;
- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPartNumber:(NSInteger)partNumber etag:(NSString *)etag;
- (void)fileUploader:(MultiPartFileUploader *)uploader didFinishUploadingFileTo:(NSString *)destinationPath;
- (void)fileUploaderDidAbort:(MultiPartFileUploader *)uploader;
@end


@interface MultiPartFileUploader : NSObject <AmazonServiceRequestDelegate, PartUploadTaskDelegate>

/**
 Location of file being uploaded on local machine
 */
@property (nonatomic, strong) NSURL *filePathUrl;

/**
 Create an instance of an uploader with S3 credentials
 @param s3Key The Access Key Id for your S3 account
 @param s3Secret The Secret Access Key for your S3 account
 @param s3Bucket The S3 bucket you want to use to store your file
 @param s3FileKey The S3 key you want to use to store your file - pass nil to have the key generated from the filePathUrl
 @returns a new instance of MultiPartFileUploader
 */
- (id)initWithS3Key:(NSString *)s3Key secret:(NSString *)s3Secret bucket:(NSString *)s3Bucket fileKey:(NSString*)s3FileKey;

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
 @returns YES if parts are successfully queued, NO if arguments are incorrect or there are problems connecting to S3
 */
- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl outstandingParts:(NSSet *)outstandingParts operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate;

/**
 Stop uploading a file
 */
- (void)cancel;

@end
