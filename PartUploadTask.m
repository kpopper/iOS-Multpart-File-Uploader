//
//  PartUploadTask.m
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 04/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "PartUploadTask.h"
#import "Reachability.h"

@implementation PartUploadTask

@synthesize delegate=_delegate;
@synthesize partNumber=_partNumber;
@synthesize data=_data;
@synthesize s3=_s3;
@synthesize upload=_upload;
@synthesize percentageUploaded=_percentageUploaded;

- (id)initWithPartNumber:(NSInteger)partNumber dataToUpload:(NSData *)data s3Client:(AmazonS3Client *)s3 s3MultipartUpload:(S3MultipartUpload *)upload
{
    self = [super init];
    if( self )
    {
        [self setPartNumber:partNumber];
        [self setData:data];
        [self setS3:s3];
        [self setUpload:upload];
        isExecuting = NO;
        isFinished = NO;
    }
    return self;
}


- (void)start
{
    if ([self isCancelled] == YES)
    {
        NSLog(@"** OPERATION CANCELED **");
        [self finish];
        return;
    }
    
    NSLog(@"Uploader has started uploading part %d", [self partNumber]);
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    bool using3G = ![self isWifiAvailable];
    
    S3UploadInputStream *stream = [S3UploadInputStream inputStreamWithData:[self data]];        
    if ( using3G ) {
        // If connected via 3G "throttle" the stream.
        stream.delay = 0.2; // In seconds
        stream.packetSize = 16; // Number of 1K blocks
    }
    
    S3UploadPartRequest *upReq = [[S3UploadPartRequest alloc] initWithMultipartUpload:[self upload]];
    upReq.partNumber = [self partNumber];
    upReq.contentLength = [[self data] length];
    upReq.stream = stream;
    upReq.delegate = self;
    
    [[self s3] uploadPart:upReq];
    
    
    // This is a horrible hack. Without this the method returns immediately and the upload delegates never get called.
    // Seems to be a threading thing. 
    // TODO: Find a more elegant solution
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (!isFinished);
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return isExecuting;
}

- (BOOL)isFinished
{
    return isFinished;
}

-(BOOL)isWifiAvailable 
{
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    return !( [r currentReachabilityStatus] == NotReachable); 
}

- (void)finish
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isSignificantIncrease:(float)percentage
{
    int mult = percentage * 100;
    float rounded = mult / 100.0f;
    if( rounded > [self percentageUploaded] )
    {
        [self setPercentageUploaded:rounded];
        return YES;
    }
    return NO;
}

#pragma mark - AmazonServiceRequestDelegate

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    [self finish];

    if( [self delegate] && [[self delegate] respondsToSelector:@selector(partUploadTaskDidFail:)])
    {
        [[self delegate] partUploadTaskDidFail:self];
    }
}
- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    [self finish];
    
    if( [self delegate] )
    {
        [[self delegate] partUploadTaskDidFail:self];
    }
}

- (void)request:(AmazonServiceRequest *)request didSendData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if(self.isCancelled) {
        [request cancel];
        [self finish];
        return;
    }
    
    float percentage = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    if( ![self isSignificantIncrease:percentage] )
    {
        return;
    }
    
    if( [self delegate] && [[self delegate] respondsToSelector:@selector(partUploadTask:didUploadPercentage:)] )
    {
        [[self delegate] partUploadTask:self didUploadPercentage:percentage];
    }
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    S3UploadPartResponse *partResponse = (S3UploadPartResponse *)response;
    
    [self finish];

    if( [self delegate] && [[self delegate] respondsToSelector:@selector(partUploadTask:didFinishUploadingPartNumber:etag:)] )
    {
        [[self delegate] partUploadTask:self didFinishUploadingPartNumber:[self partNumber] etag:[partResponse etag]];
    }
}


@end
