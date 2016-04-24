////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSExternalJournalCloud.m
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 27.02.16.
 *      Copyright © 2016 Alexandr Babenko. All rights reserved.
 *
 *      Licensed under the Apache License, Version 2.0 (the "License");
 *      you may not use this file except in compliance with the License.
 *      You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *      Unless required by applicable law or agreed to in writing, software
 *      distributed under the License is distributed on an "AS IS" BASIS,
 *      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *      See the License for the specific language governing permissions and
 *      limitations under the License.
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DSExternalJournalCloud.h"

@implementation DSExternalJournalCloud

#pragma mark - Initialization

- (instancetype)init{
    if(self= [super init]){
        journalsDictionary =  [NSMutableDictionary new];
    }
    return self;
}

+ (instancetype)sharedCloud{
    
    static DSExternalJournalCloud *sharedCloud = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCloud = [DSExternalJournalCloud new];
    });
    return sharedCloud;
}

#pragma mark - Work With Journals

- (void)createExternalJournals:(NSArray <NSString*> *)journalNames{
    
    for (NSString *journalName in journalNames) {
        [self  createExternalJournalWithName:journalName];
    }
}

- (DSJournal*)createExternalJournalWithName:(NSString*)journalName{
    
    NSAssert(journalName != nil, @"External Journal Name String can not be nil!");
    DSJournal *newJournal = [DSJournal new];
    newJournal.journalName = journalName;
    [journalsDictionary setObject:newJournal forKey:journalName];
    
    return newJournal;
}

- (DSJournal*)journalByName:(NSString*)journalName{
    
    NSAssert(journalName != nil, @"External Journal Name String can not be nil!");
    DSJournal *foundedJournal = [journalsDictionary objectForKey:journalName];
    if(! foundedJournal){
        NSLog(@"External Journal With Name %@ NOT FOUND !!!", journalName);
    }
    
    return foundedJournal;
}

- (BOOL)deleteJournalByName:(NSString*)journalName{
    
    NSAssert(journalName != nil, @"External Journal Name String can not be nil!");
    BOOL haveJournal = (BOOL)[journalsDictionary objectForKey:journalName];
    
    if(haveJournal){
        [journalsDictionary removeObjectForKey:journalName];
        return YES;
    }else{
        NSLog(@"External Journal With Name %@ NOT FOUND !!!", journalName);
        return NO;
    }
}

- (NSArray <NSString*> *)journalNamesList{
    
    return [journalsDictionary allKeys];
}

@end
