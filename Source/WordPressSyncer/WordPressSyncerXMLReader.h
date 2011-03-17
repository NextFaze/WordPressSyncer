//
//  PollDaddyXMLReader.h
//
//

#import <Foundation/Foundation.h>


@interface WordPressSyncerXMLReader : NSObject
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    NSError *error;
    NSXMLParser *parser;
}

@property (nonatomic, retain) NSError *error;

- (NSDictionary *)dictionaryForXMLData:(NSData *)data;
- (NSDictionary *)dictionaryForXMLString:(NSString *)string;

@end
