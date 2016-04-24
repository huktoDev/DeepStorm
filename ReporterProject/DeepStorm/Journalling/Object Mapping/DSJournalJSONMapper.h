////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournalJSONMapper.h
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 20.03.16.
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
#import "DSJournalMappingProtocol.h"

@class DSJournal, DSJournalRecord, DSBaseLoggedService;

/**
    <hr>
    @class DSJournalJSONMapper
    @author  HuktoDev
    @updated 20.03.2016
    @abstract Класс, использующийся для маппинга в JSON-структуры
    @discussion
    Когда требуется создать и отправить репорт - для формирования данных  репорта используется один из мапперов. Реализует DSJournalMappingProtocol
    <hr>
 
    @note Позволяет маппить в NSData следующие классы :
    <ol type="a">
        <li> объект сервиса DSBaseLoggedService </li>
        <li> объект журнала DSJournal </li>
    </ol>
 
    @see
    <a href="https://ru.wikipedia.org/wiki/JSON"> JSON структура данных </a>
 */
@interface DSJournalJSONMapper : NSObject <DSJournalMappingProtocol>

#pragma mark - DSJournalMappingProtocol
// Получение представлений данных

+ (NSData*)dataRepresentationForService:(DSBaseLoggedService*)service;
+ (NSData*)dataRepresentationForJournal:(DSJournal*)journal;


#pragma mark - JSON Representation
// JSON-представления объектов

+ (NSDictionary*)serviceJSONRepresentation:(DSBaseLoggedService*)service;
+ (NSDictionary*)journalJSONRepresentation:(DSJournal*)journal;
+ (NSDictionary*)recordJSONRepresentation:(DSJournalRecord*)record;
+ (NSDictionary*)errorJSONRepresentation:(NSError*)error;

@end
