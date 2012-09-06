MultipartUpload uses an operation queue to chunk up and upload all pieces of a large file to S3. It does not handle persistence so if you only get part way through an upload, you have to manage the process of re-uploading again.

Prerequisites
=============

1) Reachability - The best version to use is this one: [https://github.com/tonymillion/Reachability](https://github.com/tonymillion/Reachability)
1) AWSiOSSDK.framework - Part of the AWS iOS SDK download: [http://aws.amazon.com/sdkforios/](http://aws.amazon.com/sdkforios/)
1) SystemConfiguration.framework - Part of the standard iOS SDK
1) An AWS S3 account

Usage
=====

See example application.

Create and retain an instance by passing your S3 credentials:

    [self setUploader:[[[MultiPartFileUploader alloc] initWithS3Key:kS3AccessKey secret:kS3SecretKey bucket:kS3Bucket] autorelease]];

Create and retain an operation queue that can be used to do the individual part uploads:

    [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];

Pass a the URL for a locally-stored file to the uploader. Optionally set a delegate for progress updates.

    [[self uploader] uploadFileAtUrl:url operationQueue:[self queue] delegate:self];

To do:
======
