//
//  ViewController.m
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSString *s3AccessKey;
    NSString *s3SecretKey;
    NSString *s3Bucket;
}

@end

@implementation ViewController

@synthesize uploader;
@synthesize queue;
@synthesize urlField;

- (void)dealloc
{
    [uploader release];
    [queue release];
    [urlField release];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
    NSString *urlString = [[self urlField] text];
    NSURL *url = [NSURL fileURLWithPath:urlString];
    [self.uploader uploadFileAtUrl:url operationQueue:[self queue] delegate:self];
}

- (void)fileUploader:(MultiPartFileUploader *)uploader didUploadPartNumber:(NSInteger)partNumber etag:(NSString *)etag
{
    NSLog(@"File uploader did upload part number: %d and got back etag: %@", partNumber, etag);
}

@end
