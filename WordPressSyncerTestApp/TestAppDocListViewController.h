//
//  TestAppDocListViewController.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TestAppDocListViewController : UITableViewController {
	NSArray *posts;
}

- (id)initWithPosts:(NSArray *)posts;

@end
