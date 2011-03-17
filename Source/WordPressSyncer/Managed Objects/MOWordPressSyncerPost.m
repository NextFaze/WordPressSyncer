//
//  MOWordPressSyncerPost.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 16/03/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import "MOWordPressSyncerPost.h"
#import "MOWordPressSyncerBlog.h"
#import "MOWordPressSyncerComment.h"


@implementation MOWordPressSyncerPost
@dynamic postID;
@dynamic content;
@dynamic dictionaryData;
@dynamic blog;
@dynamic comments;
@dynamic title;
@dynamic pubDate;
@dynamic creator;
@dynamic commentsEtag;

- (NSDictionary *)dictionary {
    return (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:self.dictionaryData];
}

- (void)addCommentsObject:(MOWordPressSyncerComment *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"comments"] addObject:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCommentsObject:(MOWordPressSyncerComment *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"comments"] removeObject:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addComments:(NSSet *)value {    
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"comments"] unionSet:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeComments:(NSSet *)value {
    [self willChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"comments"] minusSet:value];
    [self didChangeValueForKey:@"comments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
