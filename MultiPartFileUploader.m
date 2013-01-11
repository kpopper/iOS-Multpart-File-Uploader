//
//  MultiPartFileUploader.m
//  FieldNotes
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "MultiPartFileUploader.h"

@interface MultiPartFileUploader () 
@property (nonatomic, copy) NSString *s3Key;
@property (nonatomic, copy) NSString *s3Secret;
@property (nonatomic, copy) NSString *s3Bucket;
@property (nonatomic, copy) NSString *s3FileKey;
@property (nonatomic, weak) id<MultiPartFileUploaderDelegate> delegate;
@property (nonatomic, strong) AmazonS3Client *s3;
@property (nonatomic, strong) S3MultipartUpload *upload;
@property (nonatomic, strong) S3CompleteMultipartUploadRequest *compReq;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableSet *outstandingPartNumbers;
@property (nonatomic, assign) BOOL isCancelled;
- (void)abortUpload;
@end

@implementation MultiPartFileUploader

const int PART_SIZE = (5 * 1024 * 1024); // 5MB is the smallest part size allowed for a multipart upload. (Only the last part can be smaller.)

@synthesize s3Key=_s3Key;
@synthesize s3Secret=_s3Secret;
@synthesize s3Bucket=_s3Bucket;
@synthesize s3FileKey=_s3FileKey;
@synthesize delegate=_delegate;
@synthesize s3=_s3;
@synthesize upload=_upload;
@synthesize compReq=_compReq;
@synthesize queue=_queue;
@synthesize outstandingPartNumbers=_outstandingPartNumbers;
@synthesize filePathUrl=_filePathUrl;
@synthesize isCancelled=_isCancelled;

- (id)initWithS3Key:(NSString *)s3Key secret:(NSString *)s3Secret bucket:(NSString *)s3Bucket fileKey:(NSString*)s3FileKey;
{
    self = [super init];
    if( self )
    {
        [self setS3Key:s3Key];
        [self setS3Secret:s3Secret];
        [self setS3Bucket:s3Bucket];
        [self setS3FileKey:s3FileKey];
        [self setS3:[[AmazonS3Client alloc] initWithAccessKey:[self s3Key] withSecretKey:[self s3Secret]]];
        
        [[self s3] setTimeout: 999999999];
    }
    return self;
}

- (void)dealloc
{
    [_outstandingPartNumbers removeAllObjects];
    [_queue cancelAllOperations];
}

- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate
{
    [self setFilePathUrl:filePathUrl];
    
    NSData *fileData = [NSData dataWithContentsOfURL:filePathUrl];
    int numberOfParts = [self countParts:fileData];
    
    if( delegate && [delegate respondsToSelector:@selector(fileUploader:didStartUploadingFileWithNumberOfParts:)] )
    {
        [delegate fileUploader:self didStartUploadingFileWithNumberOfParts:numberOfParts];
    }
    
    NSMutableSet *parts = [NSMutableSet setWithCapacity:numberOfParts];
    for ( NSInteger part = 1; part <= numberOfParts; part++ ) 
    {
        [parts addObject:[NSNumber numberWithInteger:part]];
    }
    
    return [self uploadFileAtUrl:filePathUrl outstandingParts:parts operationQueue:queue delegate:delegate];
}

- (BOOL)uploadFileAtUrl:(NSURL *)filePathUrl outstandingParts:(NSSet *)outstandingParts operationQueue:(NSOperationQueue *)queue delegate:(id<MultiPartFileUploaderDelegate>)delegate
{
    if (!queue) 
    {
        return NO;
    }
    
    [self setFilePathUrl:filePathUrl];
    [self setQueue:queue];
    [self setDelegate:delegate];
    [self setOutstandingPartNumbers:[NSMutableSet setWithSet:outstandingParts]];
    
    NSData *fileData = [NSData dataWithContentsOfURL:[self filePathUrl]];
    
    @try 
    {
        NSString *keyOnS3 =  self.s3FileKey ?: [self fileKeyOnS3:[[self filePathUrl] relativePath]];
        S3InitiateMultipartUploadRequest *initReq = [[S3InitiateMultipartUploadRequest alloc] initWithKey:keyOnS3 inBucket:[self s3Bucket]];
        initReq.cannedACL = [S3CannedACL publicRead];
        [self setUpload:[[[self s3] initiateMultipartUpload:initReq] multipartUpload]];
        [self setCompReq:[[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:[self upload]]];
        
        for (NSNumber *partNumber in [self outstandingPartNumbers]) 
        {
            NSInteger part = [partNumber integerValue];

            NSData *dataForPart = [self getPart:part fromData:fileData];
            
            PartUploadTask *task = [[PartUploadTask alloc] initWithPartNumber:part 
                                                                  dataToUpload:dataForPart 
                                                                      s3Client:[self s3] 
                                                             s3MultipartUpload:[self upload]];
            [task setDelegate:self];
            [[self queue] addOperation:task];
        }
        
    }
    @catch ( AmazonServiceException *exception ) 
    {
        NSLog( @"Multipart Upload Failed, Reason: %@", exception  );
    }
	@catch ( NSException *exception) 
    {
        NSLog( @"General fail: %@", exception );
    }
    
    return YES;
}

- (void)cancel
{
    if(!self.isCancelled) {
        [self setIsCancelled:YES];
        [self.queue cancelAllOperations];
        //[self.outstandingPartNumbers removeAllObjects];
        [self abortUpload];
    }
}

#pragma mark - part upload delegate methods

- (void)partUploadTaskDidFail:(PartUploadTask *)task
{
    [[self outstandingPartNumbers] removeObject:[NSNumber numberWithInteger:[task partNumber]]];
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploaderDidFailToUploadFile:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] fileUploaderDidFailToUploadFile:self];
        });
    }
}

- (void)partUploadTask:(PartUploadTask *)task didUploadPercentage:(float)progress
{
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploader:didUploadPercentage:ofPartNumber:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] fileUploader:self didUploadPercentage:progress ofPartNumber:[task partNumber]];
        });
    }

}

- (void)partUploadTask:(PartUploadTask *)task didFinishUploadingPartNumber:(NSInteger)partNumber etag:(NSString *)etag
{
    [[self outstandingPartNumbers] removeObject:[NSNumber numberWithInteger:partNumber]];
    [[self compReq] addPartWithPartNumber:partNumber withETag:etag];
    
    if( [self isCancelled] )
    {
        [self abortUpload];
        return;
    }
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploader:didUploadPartNumber:etag:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] fileUploader:self didUploadPartNumber:partNumber etag:etag];
        });
    }

    if( [[self outstandingPartNumbers] count] == 0 )
    {
        [[self s3] completeMultipartUpload:[self compReq]];

        if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploader:didFinishUploadingFileTo:)] )
        {
            [[self delegate] fileUploader:self didFinishUploadingFileTo:[[self upload] key]];
        }
    }
}

#pragma mark - utility functions

-(NSData*)getPart:(int)part fromData:(NSData*)fullData 
{
    NSRange range;
    range.length = PART_SIZE;
    range.location = (part - 1) * PART_SIZE;    
    
    int maxByte = part * PART_SIZE;
    if ( [fullData length] < maxByte ) {
        range.length = [fullData length] - range.location;
    }
    
    return [fullData subdataWithRange:range];
}

-(int)countParts:(NSData*)fullData 
{
    int q = (int)([fullData length] / PART_SIZE);
    int r = (int)([fullData length] % PART_SIZE);
    
    return ( r == 0 ) ? q : q + 1;
}

- (NSString *)fileKeyOnS3:(NSString *)filePath
{
    return [@"direct_uploads" stringByAppendingPathComponent:filePath];
}

- (void)abortUpload
{
    // We may need to call this several times. We try after each outstanding part has uploaded and eventually we should be clean.
    //S3AbortMultipartUploadRequest *abortRequest = [[S3AbortMultipartUploadRequest alloc] initWithMultipartUpload:[self upload]];
    //[[self s3] abortMultipartUpload:abortRequest];
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploaderDidAbort:)] )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] fileUploaderDidAbort:self];
        });
    }
}

@end
