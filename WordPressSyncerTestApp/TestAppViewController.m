//
//  TestAppViewController.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import "TestAppViewController.h"
#import "TestAppDocListViewController.h"

#define TestAppServerName @"ServerName"
#define TestAppServerURL @"ServerURL"
#define TestAppServerCategory @"ServerCat"

@implementation TestAppViewController

#pragma mark -

- (void)updateStats {
	NSDictionary *stats = [self.store statistics];
	NSMutableString *str = [NSMutableString string];
	for(NSString *key in [stats allKeys]) {
		[str appendFormat:@"%@: %@\n", key, [stats valueForKey:key]];
	}
	self.labelDocs.text = str;
}

- (void)setStatus:(NSString *)status {
	self.labelStatus.text = [NSString stringWithFormat:@"status: %@", status];
}

- (IBAction)buttonPressed:(id)sender {
	if(sender == self.buttonDocs) {
		TestAppDocListViewController *vc = [[TestAppDocListViewController alloc] initWithPosts:[self.store posts]];
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
	else if(sender == self.buttonReset) {
		[self.store purge];
		[self updateStats];
		[self setStatus:@"inactive"];
	}
	else if(sender == self.buttonSync) {
        self.store.serverPath = self.tfServer.text;
        self.store.categoryId = self.tfCategoryId.text;
		[self setStatus:@"syncing"];
		[self.store fetchChanges];
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
	
    self.store = [[[WordPressSyncerStore alloc] initWithName:TestAppServerName delegate:self] autorelease];

	self.tfServer.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppServerURL];
	self.tfCategoryId.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppServerCategory];
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
	
    self.store = nil;
}

- (void)dealloc {
	[_tfServer release];
	[_buttonDocs release];
	[_buttonReset release];
	[_buttonSync release];
	[_labelStatus release];
	[_labelDocs release];

	[_store release];
    [super dealloc];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == self.tfServer) {
		// save value
		[[NSUserDefaults standardUserDefaults] setValue:self.tfServer.text forKey:TestAppServerURL];
	} else if(textField == self.tfCategoryId) {
        [[NSUserDefaults standardUserDefaults] setValue:self.tfCategoryId.text forKey:TestAppServerCategory];
    }
}

#pragma mark WordPressSyncerStoreDelegate

- (void)wordPressSyncerStoreStarted:(WordPressSyncerStore *)store {
    
}

- (void)wordPressSyncerStoreCompleted:(WordPressSyncerStore *)s {
    LOG(@"sync complete");
	[self updateStats];
	[self setStatus:@"complete"];
}

- (void)wordPressSyncerStoreFailed:(WordPressSyncerStore *)s {
	[self updateStats];
	[self setStatus:@"failure"];
}

- (void)wordPressSyncerStoreProgress:(WordPressSyncerStore *)store {
    [self updateStats];
}

@end
