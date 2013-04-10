//
//  TestAppViewController.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressSyncerStore.h"

@interface TestAppViewController : UIViewController <WordPressSyncerStoreDelegate, UITextFieldDelegate> {
	WordPressSyncerStore *store;
	
	UITextField *tfServer, *tfCategoryId;
	UIButton *buttonSync, *buttonReset, *buttonDocs;
	UILabel *labelStatus, *labelDocs;
}

@property (nonatomic, retain) IBOutlet UILabel *labelStatus, *labelDocs;
@property (nonatomic, retain) IBOutlet UIButton *buttonSync, *buttonReset, *buttonDocs;
@property (nonatomic, retain) IBOutlet UITextField *tfServer, *tfCategoryId;

- (IBAction)buttonPressed:(id)sender;

@end
