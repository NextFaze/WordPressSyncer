//
//  TestAppDocViewController.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import "TestAppDocViewController.h"
#import "MOWordPressSyncerComment.h"

@interface TestAppDocViewController ()
@property (nonatomic, retain) MOWordPressSyncerPost *post;
@end

@implementation TestAppDocViewController

- (id)initWithPost:(MOWordPressSyncerPost *)p {
	if(self = [super initWithNibName:@"TestAppDocViewController" bundle:nil]) {
        self.post = p;
	}
	return self;
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableString *content = [NSMutableString string];
	[content appendFormat:@"Content:\n%@\nDictionary data:\n%@", self.post.content, [[self.post dictionary] description]];
    
    for(MOWordPressSyncerComment *comment in self.post.comments) {
        [content appendFormat:@"\nComment:\n%@\n", comment.content];
    }
	self.title = [NSString stringWithFormat:@"%@", self.post.postID];

    /*
	if([document.attachments count]) {
		NSMutableString *attachmentInfo = [NSMutableString string];
		[attachmentInfo appendFormat:@"\nAttachments:\n"];
		for(MOWordPressSyncerAttachment *att in document.attachments) {
			[attachmentInfo appendFormat:@"%@ (%@ bytes)\n", att.filename, att.length];
		}
		content = [content stringByAppendingString:attachmentInfo];
	}
     */
	
	self.labelContent.text = content;
	CGSize maxSize = CGSizeMake(260, 9999);
    CGSize size = [self.labelContent.text sizeWithFont:self.labelContent.font
									constrainedToSize:maxSize 
										lineBreakMode:self.labelContent.lineBreakMode];
	CGRect frame = self.labelContent.frame;
	frame.size = size;
	self.labelContent.frame = frame;
	
	LOG(@"size: (%.0f,%.0f)", size.width, size.height);
	[self.scrollView setContentSize:size];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    RELEASE(_labelContent);
    RELEASE(_scrollView);
    
    RELEASE(_post);
    
    [super dealloc];
}


@end
