//
//  ViewController.h
//  TestMultipartUpload
//
//  Created by Ian Kynnersley on 03/09/2012.
//  Copyright (c) 2012 Sidekick Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiPartFileUploader.h"

@interface ViewController : UIViewController <MultiPartFileUploaderDelegate>

@property (nonatomic, retain) MultiPartFileUploader *uploader;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) IBOutlet UITextView *urlField;

- (IBAction)upload:(id)sender;

@end
