//
//  TestAppDelegate.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestAppViewController.h"

@interface TestAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	UINavigationController *navController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;

@end

