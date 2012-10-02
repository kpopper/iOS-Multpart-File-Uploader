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

@synthesize partNumber=_partNumber;
@synthesize data=_data;
@synthesize s3=_s3;
@synthesize upload=_upload;

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

- (void)dealloc
{
    [_data release];
    [_s3 release];
    [_upload release];
    [super dealloc];
}

- (void)start
{
    // Ensure that this operation starts on the main thread
//    if (![NSThread isMainThread])
//    {
//        [self performSelectorOnMainThread:@selector(start)
//                               withObject:nil waitUntilDone:NO];
//        return;
//    }
//    
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

#pragma mark - AmazonServiceRequestDelegate

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPartDidFailToUploadNotification object:self userInfo:nil];
    [self finish];
}
- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPartDidFailToUploadNotification object:self userInfo:nil];
    [self finish];
}

- (void)request:(AmazonServiceRequest *)request didSendData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if( [self isCancelled] )
    { 
        [self finish];
        return;
    }
    //TODO: Send percentage complete updates
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    S3UploadPartResponse *partResponse = (S3UploadPartResponse *)response;

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    [userInfo setObject:[NSNumber numberWithInteger:[self partNumber]] forKey:@"partNumber"];
    [userInfo setObject:partResponse.etag forKey:@"etag"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPartDidFinishUploadingNotification object:self userInfo:userInfo];

    [self finish];
}


@end
