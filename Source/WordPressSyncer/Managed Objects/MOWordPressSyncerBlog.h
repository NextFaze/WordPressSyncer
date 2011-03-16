//
//  MOWordPressSyncerBlog.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOWordPressSyncerPost;

@interface MOWordPressSyncerBlog : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* posts;

@end
