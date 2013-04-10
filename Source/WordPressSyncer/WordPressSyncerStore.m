//
//  WordPressSyncerStore.m
//  WordPressSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "WordPressSyncerStore.h"
#import "WordPressSyncerError.h"
#import "ViewHelper.h"

@interface WordPressSyncerStore(WordPressSyncerStorePrivate)
- (NSManagedObjectContext *)managedObjectContext;
- (MOWordPressSyncerPost *)managedObjectPost:(NSDictionary *)postData;
- (BOOL)saveDatabase;
@end


@implementation WordPressSyncerStore

@synthesize name, delegate, error, syncer, username, password, categoryId;

#pragma mark -

- (void)initDB {
    // set up core data
    [self managedObjectContext];
    if(managedObjectContext == nil) return;  // error with core data
    
    // fetch or create blog record
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:name, @"NAME", nil];
    NSError *err = nil;
    LOG(@"data: %@", data);
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"blogByName" substitutionVariables:data];
    NSArray *blogs = [managedObjectContext executeFetchRequest:fetch error:&err];
    blog = blogs.count ? [[blogs objectAtIndex:0] retain] : nil;
    LOG(@"blog etag: %@", blog.rssEtag);
    
    if(blog == nil) {
        // add server record
        blog = [[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:managedObjectContext] retain];
        blog.name = name;
        [self saveDatabase];
    }
}

#pragma mark -

- (id)initWithName:(NSString *)n delegate:(id)d {
    if(n && (self = [super init])) {
        delegate = d;
        name = [n retain];
        
        [self performSelectorOnMainThread:@selector(initDB) withObject:nil waitUntilDone:YES];
    }
    
    return self;
}

- (void)dealloc {
    [name release];
    [serverPath release];
    [categoryId release];
    [blog release];
    [error release];
    [syncer release];
    
    [super dealloc];
}

#pragma mark -

- (void)reportError {
    [delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreFailed:) withObject:self waitUntilDone:YES];
}

- (void)reportProgress {
    if([delegate respondsToSelector:@selector(wordPressSyncerStoreProgress:)])
        [delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreProgress:) withObject:self waitUntilDone:YES];
}

// save database
- (BOOL)saveDatabase {
    NSError *err = nil;
    if (![managedObjectContext save:&err]) {
        LOG(@"error: %@, %@", err, [err userInfo]);
        [error release];
        error = [err retain];
        
        [syncer stop];
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
    blog.url = path;
}
- (NSString *)serverPath {
    return blog.url;
}

- (void)fetchChanges {
    if(blog.url) {

        [ViewHelper showProgressHUD];

        // initialise syncer
        if(syncer == nil) {
            syncer = [[WordPressSyncer alloc] initWithPath:blog.url delegate:self];
        }
        syncer.serverPath = blog.url;
        syncer.categoryId = categoryId;
        [syncer fetchWithEtag:blog.rssEtag];
    }
}

- (void)fetchComments:(NSString *)postID {
    if(blog.url) {
        // initialise syncer 
        if(syncer == nil) {
            syncer = [[WordPressSyncer alloc] initWithPath:blog.url delegate:self];
        }
        syncer.serverPath = blog.url;
        syncer.categoryId = categoryId;

        MOWordPressSyncerPost *post = [self managedObjectPost:[NSDictionary dictionaryWithObjectsAndKeys:postID, @"postID", nil]];
        if(post) {
            // etag functionality on comments rss is broken with the version of wordpress i looked at (3.0.1)
            [syncer fetchComments:postID withEtag:nil];  // post.commentsEtag
        }
    }
}

// purge this store
- (void)purge {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(purge) withObject:nil waitUntilDone:YES];
        return;
    }
    LOG(@"purging content for %@", name);
    for(MOWordPressSyncerPost *post in blog.posts) {
        [managedObjectContext deleteObject:post];
    }
    blog.rssEtag = nil;
    [self saveDatabase];
}

- (int)countForEntityName:(NSString *)entityName {
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];	
    [request release];
    
    return count;	
}

- (NSDictionary *)statistics {
    int posts = [self countForEntityName:@"Post"];
    int comments = [self countForEntityName:@"Comment"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:posts], @"posts",
            [NSNumber numberWithInt:comments], @"comments",
            [NSNumber numberWithInt:syncer.bytes], @"bytes transferred",
            [NSNumber numberWithInt:syncer.countHttpReq], @"HTTP requests",
            nil];
}

- (NSArray *)posts {
    return [blog.posts allObjects];
}

- (NSArray *)postsMatching:(NSPredicate *)predicate {	
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Post" inManagedObjectContext:managedObjectContext]];
    [request setPredicate:predicate];
    NSArray *ret = [managedObjectContext executeFetchRequest:request error:&err];
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
    if (managedObjectModel != nil) return managedObjectModel;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WordPressSyncerDB" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator.
 If the coordinator doesn't already exist, it is created and the store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) return persistentStoreCoordinator;

    NSError *err = nil;
    NSString *storePath = [[self class] storePath];
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];	
    
    // handle db upgrade
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err]) {
        LOG(@"persistent store error: %@, code = %d", err, [err code]);
        
        // delete the database and try again
        [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error];
        
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&err]) {
            LOG(@"second persistent store error: %@", err);
            [error release];
            error = [[WordPressSyncerError errorWithCode:WordPressSyncerErrorStore] retain];
            [self reportError];
        }
    }
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext != nil) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setUndoManager:nil];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
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
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"postById" substitutionVariables:data];
    NSArray *posts = [managedObjectContext executeFetchRequest:fetch error:&err];
    return posts.count ? [posts objectAtIndex:0] : nil;	
}

// return the managed object comment for the given comment
- (MOWordPressSyncerComment *)managedObjectComment:(NSDictionary *)commentData {
    NSError *err = nil;
    NSDictionary *commentId = [commentData valueForKey:@"commentID"];
    NSString *postId = [commentData valueForKey:@"postID"];
    if(postId == nil || commentId == nil) return nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:postId, @"POST_ID", commentId, @"COMMENT_ID", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"commentByIdAndPostId" substitutionVariables:data];
    NSArray *comments = [managedObjectContext executeFetchRequest:fetch error:&err];
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
        [managedObjectContext deleteObject:comment];
    }
    
    LOG(@"setting post %@ comments etag: %@", post.postID, etag);
    post.commentsEtag = etag;
    
    for(NSDictionary *commentData in comments) {
        // create new document
        MOWordPressSyncerComment *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:managedObjectContext];
        
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
    BOOL is_new = NO;
    NSDate *pubDate = [postData valueForKey:@"pubDate"];
    int age = -[pubDate timeIntervalSinceNow] / 60;   // minutes
    
    if(post == nil) {
        // create new post
        post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectContext];
        is_new = YES;
    }
    
//    if(!is_new && age > 60 * 24) {
//    if( !is_new ) {
//        // post is older than one day, do not resync
//        // TODO: configurable time interval
//        LOG(@"existing post %@ age == %d minutes, stopping sync", postID, age);
//        [syncer stop];
//        return;
//    }
    
    if(etag && ![blog.rssEtag isEqualToString:etag]) {
        LOG(@"syncer '%@' setting blog rss etag: %@", name, etag);
        blog.rssEtag = etag;
    }
    
    post.content = [postData valueForKey:@"content:encoded"];
    post.postID = [NSNumber numberWithInt:[postID intValue]];
    post.dictionaryData = [NSKeyedArchiver archivedDataWithRootObject:postData];
    post.blog = blog;
    post.pubDate = [postData valueForKey:@"pubDate"];
    post.title = [postData valueForKey:@"title"];
    post.creator = [postData valueForKey:@"dc:creator"];
    LOG(@"fetched post: %@ (%@)", postID, post.title);
    
    int commentCount = [[postData valueForKey:@"slash:comments"] intValue];
    if(commentCount > 0) {
        // download comments
        // etag functionality on comments rss is broken with the version of wordpress i looked at (3.0.1)
        [syncer fetchComments:postID withEtag:nil];  // post.commentsEtag
    }
    else if(commentCount == 0 && [post.comments count]) {
        // remove all comments
        for(MOWordPressSyncerComment *comment in post.comments) {
            [managedObjectContext deleteObject:comment];
        }
    }
    
    // save database
    [self saveDatabase];

    if([delegate respondsToSelector:@selector(wordPressSyncerStore:addedPost:)])
        [delegate wordPressSyncerStore:self addedPost:post];
    
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
    [ViewHelper dismissProgressHUD];

    [delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreCompleted:) withObject:self waitUntilDone:YES];
}

- (void)wordPressSyncer:(WordPressSyncer *)s didFailWithError:(NSError *)err {	
    LOG(@"error: %@", err);
    if(err != error) {
        [error release];
        error = [err retain];
    }
    [self reportError];
    [ViewHelper dismissProgressHUD];
}


@end
