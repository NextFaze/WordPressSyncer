//
//  TestAppViewController.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "TestAppViewController.h"
#import "TestAppDocListViewController.h"

#define TestAppServerName @"ServerName"
#define TestAppServerURL @"ServerURL"
#define TestAppServerCategory @"ServerCat"

@implementation TestAppViewController

@synthesize tfServer, tfCategoryId;
@synthesize buttonDocs, buttonReset, buttonSync, labelStatus, labelDocs;

#pragma mark -

- (void)updateStats {
	NSDictionary *stats = [store statistics];
	NSMutableString *str = [NSMutableString string];
	for(NSString *key in [stats allKeys]) {
		[str appendFormat:@"%@: %@\n", key, [stats valueForKey:key]];
	}
	labelDocs.text = str;
	//[labelDocs sizeToFit];
}

- (void)setStatus:(NSString *)status {
	labelStatus.text = [NSString stringWithFormat:@"status: %@", status];
}

- (IBAction)buttonPressed:(id)sender {
	if(sender == buttonDocs) {
		TestAppDocListViewController *vc = [[TestAppDocListViewController alloc] initWithPosts:[store posts]];
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
	else if(sender == buttonReset) {
		[store purge];
		[self updateStats];
		[self setStatus:@"inactive"];
	}
	else if(sender == buttonSync) {
        [store release];
        store = [[WordPressSyncerStore alloc] initWithPath:tfServer.text delegate:self];
        store.syncer.categoryId = tfCategoryId.text;
		[self setStatus:@"syncing"];
		[store fetchChanges];
	}
}

#pragma mark -

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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	tfServer.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppServerURL];
	tfCategoryId.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppServerCategory];
	[self updateStats];
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
	
	[store release];
	store = nil;
}

- (void)dealloc {
	[tfServer release];
	[buttonDocs release];
	[buttonReset release];
	[buttonSync release];
	[labelStatus release];
	[labelDocs release];

	[store release];
    [super dealloc];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == tfServer) {
		// save value
		[[NSUserDefaults standardUserDefaults] setValue:tfServer.text forKey:TestAppServerURL];
	} else if(textField == tfCategoryId) {
        [[NSUserDefaults standardUserDefaults] setValue:tfCategoryId.text forKey:TestAppServerCategory];
    }
}

#pragma mark WordPressSyncerStoreDelegate

- (void)wordPressSyncerStoreCompleted:(WordPressSyncerStore *)s {
	[self updateStats];
	[self setStatus:@"complete"];
}

- (void)wordPressSyncerStoreFailed:(WordPressSyncerStore *)s {
	[self updateStats];
	[self setStatus:@"failure"];
}

@end
