//
//  WordPressSyncerFetch.m
//  WordPressSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "WordPressSyncerFetch.h"
#import "NSDataAdditions.h"
#import "WordPressSyncerXMLReader.h"

#define WordPressSyncerFetchTimeout 20  // seconds

@implementation WordPressSyncerFetch

@synthesize url, delegate, error, username, password, code, type, etag, responseHeaders;

#pragma mark -

- (id)initWithURL:(NSURL *)u {
    if((self = [super init])) {
        self.url = u;
        data = [[NSMutableData alloc] init];
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
    delegate = nil;
    [url release];
    [data release];
    [error release];
    [username release];
    [password release];
    [responseHeaders release];
    [etag release];
    
    [super dealloc];
}

#pragma mark -

- (void)fetch {
    if(conn) {
        LOG(@"fetch already in progress, returning");
        return;
    }
    [data setLength:0];
    self.error = nil;
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:WordPressSyncerFetchTimeout];
    
    // add http auth string
    if(username && password) {
        NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
        NSString *authString64 = [[authString dataUsingEncoding:NSUTF8StringEncoding] encodeToBase64];
        [req addValue:[NSString stringWithFormat:@"Basic %@", authString64] forHTTPHeaderField:@"Authorization"]; 
    }
    
    if(etag) {
        LOG(@"using etag: %@", etag);
        [req addValue:etag forHTTPHeaderField:@"If-None-Match"];
    }
    
    conn = [NSURLConnection alloc];
    [conn initWithRequest:req delegate:self startImmediately:NO];
    [conn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    LOG(@"fetching URL: %@", url);
    [conn start];
    [conn release];
}

- (NSData *)data {
    return data;
}

// return data as string
- (NSString *)string {
    return [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
}

// decode the received data as XML and parse into a dictionary
- (NSDictionary *)dictionaryFromXML {
    WordPressSyncerXMLReader *reader = [[WordPressSyncerXMLReader alloc] init];
    NSDictionary *dict = [reader dictionaryForXMLData:data];
    self.error = reader.error;
    [reader release];
    
    return dict;
}

- (NSString *)responseEtag {
    NSString *et = [responseHeaders valueForKey:@"ETag"];
    if(et == nil) et = [responseHeaders valueForKey:@"Etag"];
    return et;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
    self.error = err;
    
    // call delegate before finishConnection or we might get freed before the delegate can access our data
    [delegate wordPressSyncerFetchCompleted:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //LOG(@"connection finished loading");
    
    // call delegate before finishConnection or we might get freed before the delegate can access our data
    [delegate wordPressSyncerFetchCompleted:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)res {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)res;
    if ([res respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        code = [httpResponse statusCode];
        [responseHeaders release];
        responseHeaders = [dictionary retain];
        LOG(@"response code: %d, content length: %@", code, [dictionary valueForKey:@"Content-Length"]);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    //LOG(@"received data");
    [data appendData:d];
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
    [delegate wordPressSyncerFetchCompleted:self];
}

@end
