//
//  WordPressSyncerError.m
//  WordPressSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "WordPressSyncerError.h"


@implementation WordPressSyncerError

+ (NSString *)descriptionForCode:(WordPressSyncerErrorCode)code {
	NSString *desc = nil;
	
	switch (code) {
		case WordPressSyncerErrorStore:
			desc = @"unable to initialise persistent store";
			break;
		default:
			desc = @"An error occurred";
			break;
	}
	return desc;
}

+ (WordPressSyncerError *)errorWithCode:(WordPressSyncerErrorCode)code  {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [self descriptionForCode:code], NSLocalizedDescriptionKey,
							  nil];
	WordPressSyncerError *err = [NSError errorWithDomain:WordPressSyncerErrorDomain code:code userInfo:userInfo];
	return err;
}

@end
