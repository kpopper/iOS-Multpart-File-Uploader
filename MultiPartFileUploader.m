//
//  MultiPartFileUploader.m
//  FieldNotes
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "MultiPartFileUploader.h"
#import "PartUploadTask.h"

@interface MultiPartFileUploader () 
@property (nonatomic, copy) NSString *s3Key;
@property (nonatomic, copy) NSString *s3Secret;
@property (nonatomic, copy) NSString *s3Bucket;
@property (nonatomic, assign) id<MultiPartFileUploaderDelegate> delegate;
@property (nonatomic, retain) AmazonS3Client *s3;
@property (nonatomic, retain) S3MultipartUpload *upload;
@property (nonatomic, retain) S3CompleteMultipartUploadRequest *compReq;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSMutableSet *outstandingParts;
@property (nonatomic, assign) BOOL isCancelled;
- (void)abortUpload;
@end

@implementation MultiPartFileUploader

const int PART_SIZE = (5 * 1024 * 1024); // 5MB is the smallest part size allowed for a multipart upload. (Only the last part can be smaller.)

@synthesize s3Key=_s3Key;
@synthesize s3Secret=_s3Secret;
@synthesize s3Bucket=_s3Bucket;
@synthesize delegate=_delegate;
@synthesize s3=_s3;
@synthesize upload=_upload;
@synthesize compReq=_compReq;
@synthesize queue=_queue;
@synthesize outstandingParts=_outstandingParts;
@synthesize filePathUrl=_filePathUrl;
@synthesize isCancelled=_isCancelled;

- (id)initWithS3Key:(NSString *)s3Key secret:(NSString *)s3Secret bucket:(NSString *)s3Bucket
{
    self = [super init];
    if( self )
    {
        [self setS3Key:s3Key];
        [self setS3Secret:s3Secret];
        [self setS3Bucket:s3Bucket];
        [self setS3:[[[AmazonS3Client alloc] initWithAccessKey:[self s3Key] withSecretKey:[self s3Secret]] autorelease]];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [_s3 release];
    [_upload release];
    [_compReq release];
    [_queue cancelAllOperations];
    [_queue release];
    [_s3Key release];
    [_s3Secret release];
    [_s3Bucket release];
    [_filePathUrl release];
    [super dealloc];
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
    [self setOutstandingParts:[NSMutableSet setWithSet:outstandingParts]];
    
    NSData *fileData = [NSData dataWithContentsOfURL:[self filePathUrl]];
    
    @try 
    {
        NSString *keyOnS3 = [self fileKeyOnS3:[[self filePathUrl] relativePath]];
        S3InitiateMultipartUploadRequest *initReq = [[[S3InitiateMultipartUploadRequest alloc] initWithKey:keyOnS3 inBucket:[self s3Bucket]] autorelease];
        [self setUpload:[[[self s3] initiateMultipartUpload:initReq] multipartUpload]];
        [self setCompReq:[[[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:[self upload]] autorelease]];
        
        for (NSNumber *partNumber in [self outstandingParts]) 
        {
            NSInteger part = [partNumber integerValue];

            NSData *dataForPart = [self getPart:part fromData:fileData];
            
            PartUploadTask *task = [[[PartUploadTask alloc] initWithPartNumber:part 
                                                                  dataToUpload:dataForPart 
                                                                      s3Client:[self s3] 
                                                             s3MultipartUpload:[self upload]] autorelease];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completePartUpload:) name:kPartDidFinishUploadingNotification object:task];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadDidFail:) name:kPartDidFailToUploadNotification object:task];
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
    [self setIsCancelled:YES];
    
    for (PartUploadTask *part in [self outstandingParts]) 
    {
        [part cancel];
    }
 
    [self abortUpload];
}

#pragma mark - upload delegate notifications

- (void)uploadDidFail:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPartDidFinishUploadingNotification object:[notification object]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPartDidFailToUploadNotification object:[notification object]];
    
    if( [self isCancelled] )
    {
        [self abortUpload];
    }
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploaderDidFailToUploadFile:)] )
    {
        [[self delegate] fileUploaderDidFailToUploadFile:self];
    }
}

- (void)completePartUpload:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPartDidFinishUploadingNotification object:[notification object]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPartDidFailToUploadNotification object:[notification object]];
    
    NSDictionary *userInfo = [notification userInfo];
    NSInteger partNumber = [[userInfo objectForKey:@"partNumber"] integerValue];
    NSString *etag = [userInfo objectForKey:@"etag"];
    [[self outstandingParts] removeObject:[NSNumber numberWithInteger:partNumber]];
    [[self compReq] addPartWithPartNumber:partNumber withETag:etag];
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(fileUploader:didUploadPartNumber:etag:)] )
    {
        [[self delegate] fileUploader:self didUploadPartNumber:partNumber etag:etag];
    }

    if( [[self outstandingParts] count] == 0 )
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
    S3AbortMultipartUploadRequest *abortRequest = [[[S3AbortMultipartUploadRequest alloc] initWithMultipartUpload:[self upload]] autorelease];
    [[self s3] abortMultipartUpload:abortRequest];
}

@end
