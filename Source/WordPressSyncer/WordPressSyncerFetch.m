//
//  WordPressSyncerFetch.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2013 NextFaze. All rights reserved.
//

#import "WordPressSyncerFetch.h"
#import "NSDataAdditions.h"
#import "WordPressSyncerXMLReader.h"

#define WordPressSyncerFetchTimeout 20  // seconds

@interface WordPressSyncerFetch ()
@property (nonatomic, retain) NSMutableData *mutableData;
@property (nonatomic, retain) NSURLConnection *conn;
@property (nonatomic, retain) NSDictionary *responseHeaders;
@end

@implementation WordPressSyncerFetch

- (id)initWithURL:(NSURL *)u {
    if((self = [super init])) {
        self.url = u;
        self.mutableData = [[[NSMutableData alloc] init] autorelease];
    }
    return self;
}

- (id)initWithURL:(NSURL *)u delegate:(id<WordPressSyncerFetchDelegate>)d {
    if((self = [self initWithURL:u])) {
        self.delegate = d;
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
    RELEASE(_url);
    RELEASE(_mutableData);
    RELEASE(_error);
    RELEASE(_username);
    RELEASE(_password);
    RELEASE(_responseHeaders);
    RELEASE(_etag);
    RELEASE(_postID);

    [super dealloc];
}

#pragma mark -

- (void)fetch {
    if(self.conn) {
        LOG(@"fetch already in progress, returning");
        return;
    }
    [self.mutableData setLength:0];
    self.error = nil;
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:WordPressSyncerFetchTimeout];
    
    // add http auth string
    if(self.username && self.password) {
        NSString *authString = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
        NSString *authString64 = [[authString dataUsingEncoding:NSUTF8StringEncoding] encodeToBase64];
        [req addValue:[NSString stringWithFormat:@"Basic %@", authString64] forHTTPHeaderField:@"Authorization"]; 
    }
    
    if(self.etag) {
        LOG(@"using etag: %@, request URL: %@", self.etag, req.URL);
        [req addValue:self.etag forHTTPHeaderField:@"If-None-Match"];
    }
    
    self.conn = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO] autorelease];
    [self.conn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    LOG(@"fetching URL: %@", self.url);
    [self.conn start];
}

// return data as string
- (NSString *)string {
    return [[[NSString alloc] initWithBytes:[self.data bytes] length:[self.data length] encoding:NSUTF8StringEncoding] autorelease];
}

// decode the received data as XML and parse into a dictionary
- (NSDictionary *)dictionaryFromXML {
    WordPressSyncerXMLReader *reader = [[WordPressSyncerXMLReader alloc] init];
    NSDictionary *dict = [reader dictionaryForXMLData:self.data];
    self.error = reader.error;
    [reader release];
    
    return dict;
}

- (NSString *)responseEtag {
    NSString *et = [self.responseHeaders valueForKey:@"ETag"];
    if(et == nil) et = [self.responseHeaders valueForKey:@"Etag"];
    return et;
}

- (NSData *)data {
    return [NSData dataWithData:self.mutableData];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
    self.error = err;
    
    // call delegate before finishConnection or we might get freed before the delegate can access our data
    [self.delegate wordPressSyncerFetchCompleted:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    LOG(@"finished loading.");
       
    // call delegate before finishConnection or we might get freed before the delegate can access our data
    [self.delegate wordPressSyncerFetchCompleted:self];
    
    LOG(@"delegate callback complete.");
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)res {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)res;
    if ([res respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        _code = [httpResponse statusCode];
        self.responseHeaders = dictionary;
        LOG(@"response code: %d, content length: %@, URL: %@", _code,
            [dictionary valueForKey:@"Content-Length"], res.URL);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    //LOG(@"received data");
    [self.mutableData appendData:d];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] > 0) {
        // handle bad credentials here
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    
    if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodServerTrust) {
        // makes connection work with ssl self signed certificates
        LOG(@"certificate challenge");
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];	
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    // TODO: set error here?
    [self.delegate wordPressSyncerFetchCompleted:self];
}

@end
