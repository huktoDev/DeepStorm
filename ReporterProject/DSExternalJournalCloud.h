////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSExternalJournalCloud.h
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

#import <Foundation/Foundation.h>
#import "DSJournal.h"

/*
 Например, один журнал для логгирования всех контроллеров их определенной юзер-стори.
 Например:
 - Отдельный журнал для шаблонов
 - Отдельный журнал для шаблонов
 - Отдельный журнал для контроллера нового заказа
 - Отдельный журнал для работы OrdersListView
 */

/**
    @class DSExternalJournalCloud
    @author HuktoDev
    @updated 26.03.2016
    @abstract 
 */
@interface DSExternalJournalCloud : NSObject{
    
    @private
    NSMutableDictionary <NSString*, DSJournal*> *journalsDictionary;
}

+ (instancetype)sharedCloud;

- (void)createExternalJournals:(NSArray <NSString*> *)journalNames;
- (DSJournal*)createExternalJournalWithName:(NSString*)journalName;
- (DSJournal*)journalByName:(NSString*)journalName;

- (BOOL)deleteJournalByName:(NSString*)journalName;

- (NSArray <NSString*> *)journalNamesList;


@end
