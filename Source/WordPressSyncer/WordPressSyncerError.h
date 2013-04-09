//
//  WordPressSyncerError.h
//  WordPressSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2013 NextFaze. All rights reserved.
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
