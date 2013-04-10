//
//  WordPressSyncer.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "WordPressSyncer.h"

#define MaxDownloadCount        3   // maximum number of concurrent downloads
#define MaxResponseQueueLength 20   // maximum number of outstanding responses

@implementation WordPressSyncer

@synthesize delegate, serverPath, bytes, countHttpReq, username, password;
@synthesize categoryId;

#pragma mark Private

- (NSString *)urlEncodeValue:(NSString *)str {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL,
                                                                            CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    return [result autorelease];
}

- (NSDate *)parseRssDate:(NSString *)dateString {
    // parse date
    //pubDate = "Sun, 01 Aug 2010 06:18:25 +0000";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss ZZZZ"];
    NSDate *date = dateString ? [df dateFromString:dateString] : nil;
    [df release];
    return date;
}

// extract post id from the given url
- (NSString *)parsePostID:(NSString *)url {
    NSRange rangeID = [url rangeOfString:@"=\\d+" options:NSBackwardsSearch|NSRegularExpressionSearch];
    NSString *postID = nil;
    
    if(rangeID.location != NSNotFound) {
        rangeID.location ++;
        rangeID.length --;
        postID = [url substringWithRange:rangeID];
    }
    return postID;
}

- (NSArray *)rssItems:(WordPressSyncerFetch *)fetcher {
    NSDictionary *result = [fetcher dictionaryFromXML];
    NSDictionary *rss = [result valueForKey:@"rss"];
    NSArray *ret = nil;
    
    if(fetcher.error) {
        // xml parse error
        LOG(@"error: %@", fetcher.error);
    }
    
    if(rss) result = rss;
    id items = [[result valueForKey:@"channel"] valueForKey:@"item"];
    
    if([items isKindOfClass:[NSDictionary class]]) {
        ret = [NSArray arrayWithObject:items];
    } 
    else if([items isKindOfClass:[NSArray class]]) {
        ret = items;
    }
    return ret;
}

#pragma mark -

- (id)init {
    if((self = [super init])) {
        stopped = YES;
    }
    return self;
}

- (id)initWithPath:(NSString *)path delegate:(id<WordPressSyncerDelegate>)d {
    if((self = [self init])) {
        self.serverPath = path;
        self.delegate = d;
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    [serverPath release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)rssUrl {
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%d", pagenum], @"paged",
                            @"rss2", @"feed",
                            categoryId, @"cat",
                            nil];
    NSMutableArray *paramList = [NSMutableArray array];
    for(NSString *key in [params allKeys]) {
        [paramList addObject:[NSString stringWithFormat:@"%@=%@", key, [params valueForKey:key]]];
    }
    NSString *query = [paramList componentsJoinedByString:@"&"];
    NSString *path = [NSString stringWithFormat:@"%@/?%@", serverPath, query];
    
    return path;
}

- (NSString *)commentsRssUrl:(NSString *)postID {
    // TODO: this returns ALL comments - need correct query to return only comments for this post, but seems like a permalink is reuired for this.
    //http://codex.wordpress.org/WordPress_Feeds#Post-specific_comment_feed
    return [NSString stringWithFormat:@"%@/?p=%@&feed=comments-rss2", serverPath, postID];
}

- (void)fetchNextPageWithEtag:(NSString *)etag {
    if(stopped) {
        LOG(@"stopped, returning");
        return;
    }
    pagenum++;
    NSURL *url = [NSURL URLWithString:[self rssUrl]];
    WordPressSyncerFetch *fetcher = [[WordPressSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.type = WordPressSyncerFetchTypePosts;
    fetcher.etag = etag;
    [fetcher fetch];
    [fetcher release];
    countHttpReq++;
}

- (void)fetchNextPage {
    
    // fetch after delay so main thread has enough time to display the HUD.
    // timing critical (i know, bad practice) see below stop method. RNS
    [self performSelector:@selector(fetchNextPageWithEtag:) withObject:nil afterDelay:0.5];
}

#pragma mark Public

- (void)stop {
    // abort all document fetches
    // (prevents new documents being fetched)
    stopped = YES;
    [delegate wordPressSyncerCompleted:self];
}

// reset counters
- (void)reset {
    bytes = countHttpReq = 0;
}

- (void)fetch {
    [self fetchWithEtag:nil];
}

- (void)fetchWithEtag:(NSString *)etag {
    if(!stopped) {
        LOG(@"already fetching changes, returning");
        return;
    }
        
    stopped = NO;
    pagenum = 0;
    
    [self fetchNextPageWithEtag:etag];
}

- (void)fetchComments:(NSString *)postID {
    [self fetchComments:postID withEtag:nil];
}

- (void)fetchComments:(NSString *)postID withEtag:(NSString *)etag {
    NSURL *url = [NSURL URLWithString:[self commentsRssUrl:postID]];
    WordPressSyncerFetch *fetcher = [[WordPressSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.etag = etag;
    //LOG(@"set etag to %@ for URL %@", etag, url);
    fetcher.postID = postID;
    fetcher.type = WordPressSyncerFetchTypeComments;
    [fetcher fetch];
    [fetcher release];
    countHttpReq++;
}

#pragma mark WordPressSyncerFetchDelegate

- (void)wordPressSyncerFetchCompleted:(WordPressSyncerFetch *)fetcher {
    
    if(fetcher.error) {
        // error occurred
        // TODO: retry fetches a few times ?
        // abort all outstanding fetch requests
        [self stop];
        
        // notify delegate
        [delegate wordPressSyncer:self didFailWithError:fetcher.error];
        return;
    }
    
    // fetched rss feed
    int len = [[fetcher data] length];
    bytes += len;
    
    if(fetcher.type == WordPressSyncerFetchTypePosts) {
        
        if(stopped) {
            LOG(@"stopped, returning");
            return;
        }
        
        // fetched posts
        if(fetcher.code != 200) {
            LOG(@"posts fetcher response (%d) != 200, stopping", fetcher.code);
            [self stop];
            return;
        }
        
        // split result into posts
        
        NSArray *posts = [self rssItems:fetcher];
        if(posts == nil) {
            LOG(@"no posts found");
            [self stop];
            return;
        }
        NSString *etag = [fetcher responseEtag];
        
        NSDate *dateBeforeProcessing = [NSDate dateWithTimeIntervalSinceNow:0];
        
        for(NSDictionary *post in posts) {
            NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithDictionary:post];
            
            // extract post id
            NSString *postID = [self parsePostID:[postData valueForKey:@"link"]];
            [postData setValue:postID forKey:@"postID"];
            NSDate *pubDate = [self parseRssDate:[postData valueForKey:@"pubDate"]];
            [postData setValue:pubDate forKey:@"pubDate"];
            [postData setValue:etag forKey:@"etag"];
            
            [delegate wordPressSyncer:self didFetchPost:postData];
        }
        
        NSDate *dateAfterProcessing = [NSDate dateWithTimeIntervalSinceNow:0];
        
        NSTimeInterval processingTime = [dateAfterProcessing timeIntervalSinceDate:dateBeforeProcessing];
        
        LOG(@"Processing complete (%d items). Time taken : %f", posts.count, processingTime);
        
        [self fetchNextPage];
    }
    else if(fetcher.type == WordPressSyncerFetchTypeComments) {
        // fetched comments
        
        if(fetcher.code != 200) {
            LOG(@"comments fetcher response (%d)", fetcher.code);
            return;  // unmodified comments or error
        }
        
        // split result into comments
        NSString *etag = [fetcher responseEtag];
        NSArray *comments = [self rssItems:fetcher];
        NSMutableArray *list = [NSMutableArray array];
        
        for(NSDictionary *comment in comments) {
            NSMutableDictionary *commentData = [NSMutableDictionary dictionaryWithDictionary:comment];
            NSDate *pubDate = [self parseRssDate:[commentData valueForKey:@"pubDate"]];
            NSString *postID = [self parsePostID:[commentData valueForKey:@"link"]];
            [commentData setValue:pubDate forKey:@"pubDate"];
            [commentData setValue:postID forKey:@"postID"];
            [commentData setValue:etag forKey:@"etag"];
            
            [list addObject:commentData];
        }
        NSDictionary *commentData = [NSDictionary dictionaryWithObjectsAndKeys:
                                     list, @"comments",
                                     fetcher.postID, @"postID",
                                     fetcher.etag, @"etag",  // at end, may be nil
                                     nil];

        [delegate wordPressSyncer:self didFetchComments:commentData];
    }    
}

@end
