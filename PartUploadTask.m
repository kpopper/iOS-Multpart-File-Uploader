//
//  PartUploadTask.m
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 04/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "PartUploadTask.h"
#import <AWSiOSSDK/S3/AmazonS3Client.h>
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
    }
    return self;
}

- (void)main
{
    if ([self isCancelled] == YES)
    {
        NSLog(@"** OPERATION CANCELED **");
        return;
    }

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
    
    S3UploadPartResponse *response = [[self s3] uploadPart:upReq];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    [userInfo setObject:[NSNumber numberWithInteger:[self partNumber]] forKey:@"partNumber"];
    [userInfo setObject:response.etag forKey:@"etag"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPartDidFinishUploadingNotification object:self userInfo:userInfo];
    
}

-(BOOL)isWifiAvailable 
{
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    return !( [r currentReachabilityStatus] == NotReachable); 
}


@end
