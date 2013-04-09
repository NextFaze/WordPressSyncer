//
//  WordPressSyncerDelegate.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

@class WordPressSyncer;
@class WordPressSyncerDocument;
@class WordPressSyncerAttachment;

@protocol WordPressSyncerDelegate <NSObject>

- (void)wordPressSyncer:(WordPressSyncer *)syncer didFetchPost:(NSDictionary *)post;
- (void)wordPressSyncer:(WordPressSyncer *)syncer didFetchComments:(NSDictionary *)comments;
- (void)wordPressSyncer:(WordPressSyncer *)syncer didFailWithError:(NSError *)error;
- (void)wordPressSyncerCompleted:(WordPressSyncer *)syncer;

@end
