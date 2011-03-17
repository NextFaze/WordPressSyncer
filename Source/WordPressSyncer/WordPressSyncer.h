//
//  WordPressSyncer.h
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WordPressSyncerDelegate.h"
#import "WordPressSyncerFetch.h"

@interface WordPressSyncer : NSObject <WordPressSyncerFetchDelegate> {
    NSString *serverPath;
    id<WordPressSyncerDelegate> delegate;
    
    BOOL stopped;
    
    int countHttpReq, bytes, pagenum;
    
    NSString *username, *password;
    NSString *categoryId;
}

@property (nonatomic, retain) NSString *serverPath;
@property (nonatomic, assign) id<WordPressSyncerDelegate> delegate;
@property (nonatomic, readonly) int bytes, countHttpReq;
@property (nonatomic, retain) NSString *username, *password;
@property (nonatomic, retain) NSString *categoryId;

- (id)initWithPath:(NSString *)path delegate:(id<WordPressSyncerDelegate>)d;

- (void)fetch; // fetch posts
- (void)fetchWithEtag:(NSString *)etag;
- (void)fetchComments:(NSString *)postID;
- (void)fetchComments:(NSString *)postID withEtag:(NSString *)etag;

- (void)stop;  // stop fetching data

@end
