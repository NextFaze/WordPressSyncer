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

@synthesize delegate, serverPath, bytes, countReq, username, password;
@synthesize categoryId;

#pragma mark Private

- (NSString *)urlEncodeValue:(NSString *)str {
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL,
																			CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
	return [result autorelease];
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

- (void)fetchNextPage {
    if(stopped) {
        LOG(@"stopped, returning");
        return;
    }
    pagenum++;
    NSURL *url = [NSURL URLWithString:[self rssUrl]];
    WordPressSyncerFetch *fetcher = [[WordPressSyncerFetch alloc] initWithURL:url delegate:self];
    [fetcher fetch];
    [fetcher release];
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
	bytes = countReq = 0;
}

- (void)fetch {
    if(!stopped) {
        LOG(@"already fetching changes, returning");
		return;
	}
	
	stopped = NO;
    pagenum = 0;

    [self fetchNextPage];
}

#pragma mark WordPressSyncerFetchDelegate

- (void)wordPressSyncerFetchCompleted:(WordPressSyncerFetch *)fetcher {
	
	if(stopped) {
		LOG(@"stopped, returning");
		return;
	}
	
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

    if(fetcher.code != 200) {
        LOG(@"fetcher response (%d) != 200, stopping", fetcher.code);
        [self stop];
        return;
    }

    // split result into posts
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    NSDictionary *result = [fetcher dictionaryFromXML];
    NSArray *posts = [[[result valueForKey:@"rss"] valueForKey:@"channel"] valueForKey:@"item"];    
    for(NSDictionary *post in posts) {
        NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithDictionary:post];

        // extract post id
        NSString *link = [postData valueForKey:@"link"];
        NSRange rangeID = [link rangeOfString:@"=" options:NSBackwardsSearch];
        NSString *postID = rangeID.location != NSNotFound ? [link substringFromIndex:rangeID.location + 1] : nil;        
        [postData setValue:postID forKey:@"postID"];

        // parse publish date
        //pubDate = "Sun, 01 Aug 2010 06:18:25 +0000";
        [df setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss ZZZZ"];
        NSString *pubDate = [postData valueForKey:@"pubDate"];
        NSDate *date = pubDate ? [df dateFromString:pubDate] : nil;
        if(date) [postData setValue:date forKey:@"pubDate"];
        
        [delegate wordPressSyncer:self didFetchPost:postData];
    }
    [df release];
    
    [self fetchNextPage];
}

@end


