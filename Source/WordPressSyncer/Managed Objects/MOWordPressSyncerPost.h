//
//  MOWordPressSyncerPost.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOWordPressSyncerBlog, MOWordPressSyncerComment;

@interface MOWordPressSyncerPost : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * creator;
@property (nonatomic, retain) NSString * commentsEtag;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) NSData * dictionaryData;
@property (nonatomic, retain) MOWordPressSyncerBlog * blog;
@property (nonatomic, retain) NSSet* comments;

- (NSDictionary *)dictionary;

@end
