//
//  WordPressSyncerFetch.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WordPressSyncerFetchDelegate;

typedef enum {
    WordPressSyncerFetchTypePosts,
    WordPressSyncerFetchTypeComments
} WordPressSyncerFetchType;

@interface WordPressSyncerFetch : NSObject {
    NSError *error;
    NSMutableData *data;
    NSURL *url;
    NSURLConnection *conn;
    NSDictionary *responseHeaders;
    NSString *username, *password;
    NSString *etag;
    int code;
    WordPressSyncerFetchType type;
    
    id<WordPressSyncerFetchDelegate> delegate;
}


@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) id<WordPressSyncerFetchDelegate> delegate;
@property (nonatomic, retain) NSString *username, *password, *etag;
@property (nonatomic, readonly) int code;
@property (nonatomic, assign) WordPressSyncerFetchType type;
@property (nonatomic, readonly) NSDictionary *responseHeaders;

- (id)initWithURL:(NSURL *)u;
- (id)initWithURL:(NSURL *)u delegate:(id<WordPressSyncerFetchDelegate>)d;

- (void)fetch;
- (NSData *)data;
- (NSString *)string;
- (NSDictionary *)dictionaryFromXML;

- (NSString *)responseEtag;

@end

@protocol WordPressSyncerFetchDelegate

- (void)wordPressSyncerFetchCompleted:(WordPressSyncerFetch *)fetcher;

@end
