//
//  WordPressSyncerStore.h
//  WordPressSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WordPressSyncer.h"
#import <CoreData/CoreData.h>
#import "MOWordPressSyncerBlog.h"
#import "MOWordPressSyncerPost.h"
#import "MOWordPressSyncerComment.h"

@protocol WordPressSyncerStoreDelegate;

@interface WordPressSyncerStore : NSObject <WordPressSyncerDelegate> {
    WordPressSyncer *syncer;
    NSString *name, *serverPath;
    
    // core data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;	
    
    NSError *error;
    
    MOWordPressSyncerBlog *blog;
    NSObject<WordPressSyncerStoreDelegate> *delegate;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, retain) NSString *serverPath, *categoryId;
@property (nonatomic, retain) NSObject<WordPressSyncerStoreDelegate> *delegate;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) WordPressSyncer *syncer;
@property (nonatomic, retain) NSString *username, *password;

- (id)initWithName:(NSString *)name delegate:(id)d;

- (void)fetchChanges;
- (void)fetchComments:(NSString *)postID;
- (void)purge;
- (NSDictionary *)statistics;

- (NSArray *)posts;
- (NSArray *)postsMatching:(NSPredicate *)predicate;

@end


@protocol WordPressSyncerStoreDelegate <NSObject>

- (void)wordPressSyncerStoreCompleted:(WordPressSyncerStore *)store;
- (void)wordPressSyncerStoreFailed:(WordPressSyncerStore *)store;

@optional
- (void)wordPressSyncerStoreProgress:(WordPressSyncerStore *)store;
- (void)wordPressSyncerStore:(WordPressSyncerStore *)store addedPost:(MOWordPressSyncerPost *)post;

@end
