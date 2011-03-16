//
//  WordPressSyncerStore.m
//  WordPressSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "WordPressSyncerStore.h"
#import "WordPressSyncerError.h"

@interface WordPressSyncerStore(WordPressSyncerStorePrivate)
- (NSManagedObjectContext *)managedObjectContext;
- (BOOL)saveDatabase;
@end


@implementation WordPressSyncerStore

@synthesize name, delegate, error, syncer, username, password, serverPath;

- (id)initWithPath:(NSString *)url delegate:(id)d {
	if(url && (self = [super init])) {
		delegate = d;
        serverPath = [url retain];
        
		// set up core data
		[self managedObjectContext];
		if(managedObjectContext == nil) return self;  // error with core data

		// initialise syncer 
		syncer = [[WordPressSyncer alloc] initWithPath:url delegate:self];

		// fetch or create blog record
		NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", nil];
		NSError *err = nil;
        LOG(@"data: %@", data);
		NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"blogByURL" substitutionVariables:data];
		NSArray *blogs = [managedObjectContext executeFetchRequest:fetch error:&err];
		blog = blogs.count ? [[blogs objectAtIndex:0] retain] : nil;
		
		if(blog == nil) {
			// add server record
			blog = [[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:managedObjectContext] retain];
			[self saveDatabase];
		}
	}
	
	return self;
}

- (void)dealloc {
	[name release];
	[serverPath release];
	[blog release];
	[error release];
	[syncer release];
	
	[super dealloc];
}

#pragma mark -

// save database
- (BOOL)saveDatabase {
	NSError *err = nil;
	if (![managedObjectContext save:&err]) {
		LOG(@"error: %@, %@", err, [err userInfo]);
		[error release];
		error = [err retain];
		
		[syncer stop];
		[delegate wordPressSyncerStoreFailed:self];
	}
	return err ? NO : YES;
}

- (void)reportError {
	[delegate performSelectorOnMainThread:@selector(wordPressSyncerStoreFailed:) withObject:self waitUntilDone:YES];
}

#pragma mark -

-(void)fetchChanges {
	[syncer fetch];  // detect if database has been deleted since last fetch - purge all local data in that case.
}

// purge this store
- (void)purge {
	LOG(@"purging content for %@", name);
	for(MOWordPressSyncerPost *post in blog.posts) {
		[managedObjectContext deleteObject:post];
	}
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
	NSString *dbfile = [NSString stringWithFormat:@"WordPressSyncerStore.sqlite"];
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:dbfile]];	
	
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
    NSDictionary *commentId = [commentData valueForKey:@"commentId"];
    NSString *postId = [commentData valueForKey:@"postID"];
    if(postId == nil || commentId == nil) return nil;
	NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:postId, @"POST_ID", commentId, @"COMMENT_ID", nil];
	NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"commentByIdAndPostId" substitutionVariables:data];
	NSArray *comments = [managedObjectContext executeFetchRequest:fetch error:&err];
	return comments.count ? [comments objectAtIndex:0] : nil;	
}

#pragma mark WordPressSyncerDelegate

/*

- (void)wordPressSyncer:(WordPressSyncer *)s didFetchComment:(NSDictionary *)commentData {
	LOG(@"fetched comment: %@", commentData);
	
	// save document
	// add/update server record
	MOWordPressSyncerComment *document = [self managedObjectDocument:doc];
	NSDictionary *dict = [doc dictionary];
	NSData *dictData = [NSKeyedArchiver archivedDataWithRootObject:dict];
	
	if(document == nil) {
		// create new document
		document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:managedObjectContext];
	}
	
	document.documentId = doc.documentId;
	document.revision = doc.revision;
	document.content = doc.content;
	document.dictionaryData = dictData;
	document.type = [dict valueForKey:@"type"];
	document.parentId = [dict valueForKey:@"parentId"];
	document.database = db;
	document.length = [NSNumber numberWithInt:[document.content length]];

	// save database (updates sequence id)
	[self saveDatabase:doc.sequenceId];
	
	for(WordPressSyncerAttachment *att in doc.attachments) {
		// check if we need to download attachment (revpos)
		MOWordPressSyncerAttachment *attachment = [self managedObjectAttachment:att];
		if(attachment == nil || ([attachment.revpos intValue] != att.revpos)) {
			// attachment not yet downloaded or revision has increased, download attachment
			[syncer fetchDocument:doc attachment:att];
		}
	}
}
 */

- (void)wordPressSyncer:(WordPressSyncer *)s didFetchPost:(NSDictionary *)postData {
    MOWordPressSyncerPost *post = [self managedObjectPost:postData];
    NSString *postID = [postData valueForKey:@"postID"];

	if(post == nil) {
		// create new post
		post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectContext];
	}
    
	post.content = [postData valueForKey:@"content:encoded"];
	post.postID = [NSNumber numberWithInt:[postID intValue]];
	post.dictionaryData = [NSKeyedArchiver archivedDataWithRootObject:postData];
    LOG(@"fetched post: %@", postID);
    
	// save database
	[self saveDatabase];
}

- (void)wordPressSyncerCompleted:(WordPressSyncer *)syncer {
    [delegate wordPressSyncerStoreCompleted:self];
}

- (void)wordPressSyncer:(WordPressSyncer *)s didFailWithError:(NSError *)err {	
	LOG(@"error: %@", err);
	if(err != error) {
		[error release];
		error = [err retain];
	}
	[self reportError];
}


@end
