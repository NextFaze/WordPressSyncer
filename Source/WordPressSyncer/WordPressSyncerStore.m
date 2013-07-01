//
//  WordPressSyncerStore.m
//  WordPressSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import "WordPressSyncerStore.h"
#import "WordPressSyncerError.h"

@interface WordPressSyncerStore ()

// core data
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) MOWordPressSyncerBlog *blog;
@property (nonatomic, retain) NSError *error;

@end

@implementation WordPressSyncerStore

#pragma mark -

- (void)initDB {
    // set up core data
    [self managedObjectContext];
    if(_managedObjectContext == nil) return;  // error with core data
    
    // fetch or create blog record
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"NAME", nil];
    NSError *err = nil;
    LOG(@"data: %@", data);
    NSFetchRequest *fetch = [_managedObjectModel fetchRequestFromTemplateWithName:@"blogByName" substitutionVariables:data];
    NSArray *blogs = [_managedObjectContext executeFetchRequest:fetch error:&err];
    self.blog = blogs.count ? [blogs objectAtIndex:0] : nil;
    LOG(@"blog etag: %@", self.blog.rssEtag);
    
    if(self.blog == nil) {
        // add server record
        self.blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.managedObjectContext];
        self.blog.name = self.name;
        [self saveDatabase];
    }
}

#pragma mark -

- (id)initWithName:(NSString *)n delegate:(id)d {
    if(n && (self = [super init])) {
        self.delegate = d;
        _name = [n retain];
        
        [self performSelectorOnMainThread:@selector(initDB) withObject:nil waitUntilDone:YES];
    }
    
    return self;
}

- (void)dealloc {
    RELEASE(_name);
    RELEASE(_categoryId);
    RELEASE(_blog);
    RELEASE(_error);
    RELEASE(_syncer);
        
    [super dealloc];
}

#pragma mark -

- (void)reportError {
    [self.delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreFailed:) withObject:self waitUntilDone:YES];
}

- (void)reportProgress {
    if([self.delegate respondsToSelector:@selector(wordPressSyncerStoreProgress:)])
        [self.delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreProgress:) withObject:self waitUntilDone:YES];
}

// save database
- (BOOL)saveDatabase {
    NSError *err = nil;
    if (![self.managedObjectContext save:&err]) {
        LOG(@"error: %@, %@", err, [err userInfo]);
        self.error = err;
        
        [self.syncer stop];
        [self reportError];
    }
    
    [self reportProgress];

    return err ? NO : YES;
}

#pragma mark -

+ (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)storePath {
    NSString *dbfile = [NSString stringWithFormat:@"WordPressSyncerStore.sqlite"];
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:dbfile];
    return storePath;
}

- (void)setServerPath:(NSString *)path {
    self.blog.url = path;
}
- (NSString *)serverPath {
    return self.blog.url;
}

- (void)fetchChanges {
    if(self.blog.url) {
        
        if ([self.delegate respondsToSelector:@selector(wordPressSyncerStoreStarted:)]) {
            [self.delegate wordPressSyncerStoreStarted:self];
        }

        // initialise syncer
        if(self.syncer == nil) {
            _syncer = [[WordPressSyncer alloc] initWithPath:self.blog.url delegate:self];
        }
        self.syncer.serverPath = self.blog.url;
        self.syncer.categoryId = self.categoryId;
        [self.syncer fetchWithEtag:self.blog.rssEtag];
    }
}

- (void)fetchComments:(NSString *)postID {
    if(self.blog.url) {
        // initialise syncer 
        if(_syncer == nil) {
            _syncer = [[WordPressSyncer alloc] initWithPath:self.blog.url delegate:self];
        }
        self.syncer.serverPath = self.blog.url;
        self.syncer.categoryId = self.categoryId;

        MOWordPressSyncerPost *post = [self managedObjectPost:[NSDictionary dictionaryWithObjectsAndKeys:postID, @"postID", nil]];
        if(post) {
            // etag functionality on comments rss is broken with the version of wordpress i looked at (3.0.1)
            [self.syncer fetchComments:postID withEtag:nil];  // post.commentsEtag
        }
    }
}

// purge this store
- (void)purge {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(purge) withObject:nil waitUntilDone:YES];
        return;
    }
    LOG(@"purging content for %@", self.name);
    for(MOWordPressSyncerPost *post in self.blog.posts) {
        [self.managedObjectContext deleteObject:post];
    }
    self.blog.rssEtag = nil;
    [self saveDatabase];
}

- (int)countForEntityName:(NSString *)entityName {
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext]];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
    [request release];
    
    return count;	
}

- (NSDictionary *)statistics {
    int posts = [self countForEntityName:@"Post"];
    int comments = [self countForEntityName:@"Comment"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:posts], @"posts",
            [NSNumber numberWithInt:comments], @"comments",
            [NSNumber numberWithInt:self.syncer.bytes], @"bytes transferred",
            [NSNumber numberWithInt:self.syncer.countHttpReq], @"HTTP requests",
            nil];
}

- (NSArray *)posts {
    return [self.blog.posts allObjects];
}

- (NSArray *)postsMatching:(NSPredicate *)predicate {	
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Post" inManagedObjectContext:self.managedObjectContext]];
    [request setPredicate:predicate];
    NSArray *ret = [self.managedObjectContext executeFetchRequest:request error:&err];
    [request release];
    
    return ret;
}

#pragma mark -

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) return _managedObjectModel;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WordPressSyncerDB" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator.
 If the coordinator doesn't already exist, it is created and the store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) return _persistentStoreCoordinator;

    NSError *err = nil;
    NSString *storePath = [[self class] storePath];
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];	
    
    // handle db upgrade
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err]) {
        LOG(@"persistent store error: %@, code = %d", err, [err code]);
        
        // delete the database and try again
        [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&err];
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&err]) {
            LOG(@"second persistent store error: %@", err);
            self.error = (NSError *)[WordPressSyncerError errorWithCode:WordPressSyncerErrorStore];
            [self reportError];
        }
    }
    
    return _persistentStoreCoordinator;
}

/**
 Returns the managed object context.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext != nil) return _managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setUndoManager:nil];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return _managedObjectContext;
}

/*
 - (void)mainThreadDatabaseMerge:(NSNotification*)notification {
 [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
 }
 - (void)managedObjectContextChanges:(NSNotification*)notification {
 [self performSelectorOnMainThread:@selector(mainThreadDatabaseMerge:) withObject:notification waitUntilDone:YES];
 }
 */

// return the managed object post for the given post
- (MOWordPressSyncerPost *)managedObjectPost:(NSDictionary *)postData {
    NSError *err = nil;
    NSString *postId = [postData valueForKey:@"postID"];
    if(postId == nil) return nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:postId, @"POST_ID", nil];
    NSFetchRequest *fetch = [_managedObjectModel fetchRequestFromTemplateWithName:@"postById" substitutionVariables:data];
    NSArray *posts = [_managedObjectContext executeFetchRequest:fetch error:&err];
    return posts.count ? [posts objectAtIndex:0] : nil;	
}

// return the managed object comment for the given comment
- (MOWordPressSyncerComment *)managedObjectComment:(NSDictionary *)commentData {
    NSError *err = nil;
    NSDictionary *commentId = [commentData valueForKey:@"commentID"];
    NSString *postId = [commentData valueForKey:@"postID"];
    if(postId == nil || commentId == nil) return nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:postId, @"POST_ID", commentId, @"COMMENT_ID", nil];
    NSFetchRequest *fetch = [_managedObjectModel fetchRequestFromTemplateWithName:@"commentByIdAndPostId" substitutionVariables:data];
    NSArray *comments = [_managedObjectContext executeFetchRequest:fetch error:&err];
    return comments.count ? [comments objectAtIndex:0] : nil;	
}

#pragma mark WordPressSyncerDelegate callbacks (to be run on main thread)

- (void)syncerDidFetchComments:(NSDictionary *)commentData {
    NSArray *comments = [commentData valueForKey:@"comments"];
    NSString *etag = [commentData valueForKey:@"etag"];
    MOWordPressSyncerPost *post = [self managedObjectPost:commentData];
    
    if(post == nil) {
        LOG(@"could not find post for comments, skipping");
        return;
    }
    
    // remove all existing comments
    for(MOWordPressSyncerComment *comment in post.comments) {
        [_managedObjectContext deleteObject:comment];
    }
    
    LOG(@"setting post %@ comments etag: %@", post.postID, etag);
    post.commentsEtag = etag;
    
    for(NSDictionary *commentData in comments) {
        // create new document
        MOWordPressSyncerComment *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:_managedObjectContext];
        
        comment.title = [commentData valueForKey:@"title"];
        comment.content = [commentData valueForKey:@"description"];
        comment.pubDate = [commentData valueForKey:@"pubDate"];
        comment.creator = [commentData valueForKey:@"dc:creator"];
        comment.post = post;
    }
    LOG(@"fetched %d comments for post: %@", [comments count], post.postID);
    
    // save database
    [self saveDatabase];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              post.postID, @"postID",
                              post, @"post",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WordPressSyncerStoreFetchedCommentsNotification" object:self userInfo:userInfo];
}

- (void)syncerDidFetchPost:(NSDictionary *)postData {
    MOWordPressSyncerPost *post = [self managedObjectPost:postData];
    NSString *postID = [postData valueForKey:@"postID"];
    NSString *etag = [postData valueForKey:@"etag"];
    //NSDate *pubDate = [postData valueForKey:@"pubDate"];
    //int age = -[pubDate timeIntervalSinceNow] / 60;   // minutes
    
    if(post == nil) {
        // create new post
        post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:_managedObjectContext];
    }
    
//    if(!is_new && age > 60 * 24) {
//    if( !is_new ) {
//        // post is older than one day, do not resync
//        // TODO: configurable time interval
//        LOG(@"existing post %@ age == %d minutes, stopping sync", postID, age);
//        [syncer stop];
//        return;
//    }
    
    if(etag && ![self.blog.rssEtag isEqualToString:etag]) {
        LOG(@"syncer '%@' setting blog rss etag: %@", self.name, etag);
        self.blog.rssEtag = etag;
    }
    
    post.content = [postData valueForKey:@"content:encoded"];
    post.postID = [NSNumber numberWithInt:[postID intValue]];
    post.dictionaryData = [NSKeyedArchiver archivedDataWithRootObject:postData];
    post.blog = self.blog;
    post.pubDate = [postData valueForKey:@"pubDate"];
    post.title = [postData valueForKey:@"title"];
    post.creator = [postData valueForKey:@"dc:creator"];
    LOG(@"fetched post: %@ (%@)", postID, post.title);
    
    int commentCount = [[postData valueForKey:@"slash:comments"] intValue];
    if(commentCount > 0) {
        // download comments
        // etag functionality on comments rss is broken with the version of wordpress i looked at (3.0.1)
        [self.syncer fetchComments:postID withEtag:nil];  // post.commentsEtag
    }
    else if(commentCount == 0 && [post.comments count]) {
        // remove all comments
        for(MOWordPressSyncerComment *comment in post.comments) {
            [self.managedObjectContext deleteObject:comment];
        }
    }
    
    // save database
    [self saveDatabase];

    if([self.delegate respondsToSelector:@selector(wordPressSyncerStore:addedPost:)])
        [self.delegate wordPressSyncerStore:self addedPost:post];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              post.postID, @"postID",
                              post, @"post",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WordPressSyncerStoreFetchedPostNotification" object:self userInfo:userInfo];
}

#pragma mark WordPressSyncerDelegate

- (void)wordPressSyncer:(WordPressSyncer *)syncer didFetchComments:(NSDictionary *)commentData {
    [self performSelectorOnMainThread:@selector(syncerDidFetchComments:) withObject:commentData waitUntilDone:YES];
}

- (void)wordPressSyncer:(WordPressSyncer *)s didFetchPost:(NSDictionary *)postData {
    [self performSelectorOnMainThread:@selector(syncerDidFetchPost:) withObject:postData waitUntilDone:YES];
}

- (void)wordPressSyncerCompleted:(WordPressSyncer *)syncer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate wordPressSyncerStoreCompleted:self];
    });
}

- (void)wordPressSyncer:(WordPressSyncer *)s didFailWithError:(NSError *)err {	
    LOG(@"error: %@", err);
    self.error = err;
    [self reportError];
}


@end
