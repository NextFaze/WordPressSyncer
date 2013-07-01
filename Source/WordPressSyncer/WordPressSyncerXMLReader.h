//
//  PollDaddyXMLReader.h
//
//

#import <Foundation/Foundation.h>


@interface WordPressSyncerXMLReader : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain) NSError *error;

- (NSDictionary *)dictionaryForXMLData:(NSData *)data;
- (NSDictionary *)dictionaryForXMLString:(NSString *)string;

@end
