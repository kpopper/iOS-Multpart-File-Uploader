//
//  ViewController.m
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "ViewController.h"
#import "MultiPartFileUploader.h"

@interface ViewController ()
{
    NSString *s3AccessKey;
    NSString *s3SecretKey;
    NSString *s3Bucket;
}

@end

@implementation ViewController

@synthesize uploader=_uploader;
@synthesize queue=_queue;
@synthesize urlField=_urlField;

- (void)dealloc
{
    [_uploader release];
    [_queue release];
    [_urlField release];
    [super dealloc];
}

- (void)getEnvironmentVariables
{
    NSDictionary* env = [[NSProcessInfo processInfo] environment];
    
    s3AccessKey = [env objectForKey:@"S3AccessKey"];
    s3SecretKey = [env objectForKey:@"S3SecretKey"];
    s3Bucket = [env objectForKey:@"S3Bucket"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self getEnvironmentVariables];
    
    self.uploader = [[[MultiPartFileUploader alloc] initWithS3Key:s3AccessKey secret:s3SecretKey bucket:s3Bucket] autorelease];
    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    [self.queue setMaxConcurrentOperationCount:2];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [self setUrlField:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)upload:(id)sender
{
    NSString *urlString = [self.urlField text];
    NSURL *url = [NSURL fileURLWithPath:urlString];
    [self.uploader uploadFileAtUrl:url operationQueue:self.queue delegate:self];
    
    [self.urlField resignFirstResponder];
}

- (IBAction)cancel:(id)sender
{
    [self.uploader cancel];
    NSLog(@"Upload has been manually cancelled");
}

- (void)fileUploader:(MultiPartFileUploader *)uploader didStartUploadingFileWithNumberOfParts:(NSInteger)numberOfParts
{
    NSLog(@"Uploader has split file '%@' into %d parts", uploader.filePathUrl, numberOfParts);
}

- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPercentage:(float)percentage ofPartNumber:(NSInteger)partNumber
{
    //NSLog(@"Part %d - %1.0f percent complete", partNumber, percentage * 100);
}

- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPartNumber:(NSInteger)partNumber etag:(NSString *)etag
{
    NSLog(@"Uploader did upload part number %d of file '%@' and got back etag: %@", partNumber, uploader.filePathUrl, etag);
}

- (void)fileUploader:(MultiPartFileUploader *)uploader didFinishUploadingFileTo:(NSString *)destinationPath
{
    NSLog(@"Uploader has finished uploading file '%@' to %@", uploader.filePathUrl, destinationPath);
}


@end
