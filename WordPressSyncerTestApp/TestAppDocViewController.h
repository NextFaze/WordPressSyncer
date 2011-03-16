//
//  TestAppDocViewController.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MOWordPressSyncerPost.h"


@interface TestAppDocViewController : UIViewController {
	MOWordPressSyncerPost *post;
	UIScrollView *scrollView;
	UILabel *labelContent;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UILabel *labelContent;

- (id)initWithPost:(MOWordPressSyncerPost *)post;

@end
