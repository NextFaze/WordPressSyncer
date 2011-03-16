//
//  WordPressSyncerDelegate.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

@class WordPressSyncer;
@class WordPressSyncerDocument;
@class WordPressSyncerAttachment;

@protocol WordPressSyncerDelegate <NSObject>

- (void)wordPressSyncer:(WordPressSyncer *)syncer didFetchPost:(NSDictionary *)post;
- (void)wordPressSyncer:(WordPressSyncer *)syncer didFetchComment:(NSDictionary *)comment;
- (void)wordPressSyncer:(WordPressSyncer *)syncer didFailWithError:(NSError *)error;
- (void)wordPressSyncerCompleted:(WordPressSyncer *)syncer;

@end
