//
//  MOWordPressSyncerPost.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOWordPressSyncerBlog, MOWordPressSyncerComment;

@interface MOWordPressSyncerPost : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSData * dictionaryData;
@property (nonatomic, retain) MOWordPressSyncerBlog * blog;
@property (nonatomic, retain) NSSet* comments;

@end
