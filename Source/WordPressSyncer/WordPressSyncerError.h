//
//  WordPressSyncerError.h
//  WordPressSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WordPressSyncerErrorDomain @"WordPressSyncer"

typedef enum {
    WordPressSyncerErrorStore,
} WordPressSyncerErrorCode;

@interface WordPressSyncerError : NSObject {
    
}

+ (WordPressSyncerError *)errorWithCode:(WordPressSyncerErrorCode)code;

@end
