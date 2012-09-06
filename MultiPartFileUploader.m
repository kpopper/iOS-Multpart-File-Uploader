//
//  MultiPartFileUploader.m
//  FieldNotes
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "MultiPartFileUploader.h"
#import "PartUploadTask.h"

@implementation MultiPartFileUploader

const int PART_SIZE = (5 * 1024 * 1024); // 5MB is the smallest part size allowed for a multipart upload. (Only the last part can be smaller.)

@synthesize s3Key=_s3Key;
@synthesize s3Secret=_s3Secret;
@synthesize s3Bucket=_s3Bucket;
@synthesize delegate=_delegate;
@synthesize filePathUrl=_filePathUrl;
@synthesize s3=_s3;
@synthesize compReq=_compReq;
@synthesize queue=_queue;
@synthesize outstandingParts=_outstandingParts;

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
    NSData *fileData = [NSData dataWithContentsOfURL:filePathUrl];
    int numberOfParts = [self countParts:fileData];
    
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
    
    [self setQueue:queue];
    [self setDelegate:delegate];
    [self setFilePathUrl:filePathUrl];
    [self setOutstandingParts:[NSMutableSet setWithSet:outstandingParts]];
    
    NSData *fileData = [NSData dataWithContentsOfURL:filePathUrl];
    NSString *fileName = [filePathUrl lastPathComponent];
    
    @try 
    {
        S3InitiateMultipartUploadRequest *initReq = [[[S3InitiateMultipartUploadRequest alloc] initWithKey:fileName inBucket:[self s3Bucket]] autorelease];
        S3MultipartUpload *upload = [[[self s3] initiateMultipartUpload:initReq] multipartUpload];
        [self setCompReq:[[[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:upload] autorelease]];
        
        for (NSNumber *partNumber in [self outstandingParts]) 
        {
            NSInteger part = [partNumber integerValue];

            NSData *dataForPart = [self getPart:part fromData:fileData];
            
            PartUploadTask *task = [[[PartUploadTask alloc] initWithPartNumber:part 
                                                                  dataToUpload:dataForPart 
                                                                      s3Client:[self s3] 
                                                             s3MultipartUpload:upload] autorelease];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completePartUpload:) name:kPartDidFinishUploadingNotification object:task];
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

- (void)completePartUpload:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPartDidFinishUploadingNotification object:[notification object]];
    
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
    }

}

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

@end
