//
//  WordPressSyncerFetch.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WordPressSyncerFetchDelegate;

typedef enum {
    WordPressSyncerFetchTypePosts,
    WordPressSyncerFetchTypeComments
} WordPressSyncerFetchType;

@interface WordPressSyncerFetch : NSObject

@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) id<WordPressSyncerFetchDelegate> delegate;
@property (nonatomic, retain) NSString *username, *password, *etag, *postID;
@property (nonatomic, readonly) int code;
@property (nonatomic, assign) WordPressSyncerFetchType type;
@property (nonatomic, readonly) NSDictionary *responseHeaders;

- (id)initWithURL:(NSURL *)u;
- (id)initWithURL:(NSURL *)u delegate:(id<WordPressSyncerFetchDelegate>)d;

- (void)fetch;
- (NSString *)string;
- (NSDictionary *)dictionaryFromXML;
- (NSData *)data;
- (NSString *)responseEtag;

@end

@protocol WordPressSyncerFetchDelegate

- (void)wordPressSyncerFetchCompleted:(WordPressSyncerFetch *)fetcher;

@end
