//
//  MOWordPressSyncerComment.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOWordPressSyncerPost;

@interface MOWordPressSyncerComment : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * commentID;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * creator;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) MOWordPressSyncerPost * post;

@end
