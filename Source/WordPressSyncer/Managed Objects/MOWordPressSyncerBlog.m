//
//  MOWordPressSyncerBlog.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2013 NextFaze. All rights reserved.
//

#import "MOWordPressSyncerBlog.h"
#import "MOWordPressSyncerPost.h"


@implementation MOWordPressSyncerBlog
@dynamic url;
@dynamic name;
@dynamic posts;
@dynamic rssEtag;

- (void)addPostsObject:(MOWordPressSyncerPost *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"posts"] addObject:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removePostsObject:(MOWordPressSyncerPost *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"posts"] removeObject:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addPosts:(NSSet *)value {    
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"posts"] unionSet:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removePosts:(NSSet *)value {
    [self willChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"posts"] minusSet:value];
    [self didChangeValueForKey:@"posts" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
