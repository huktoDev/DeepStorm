////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournalMappingProtocol.h
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

@class DSBaseLoggedService, DSJournal;

/**
    @def DS_DEFAULT_OBJECT_MAPPER
    Класс маппера по-умолчанию
 */
/**
    @def DS_DEFAULT_MAPPING_TYPE
    Тип маппинга по-умолчанию
 */

#define DS_DEFAULT_OBJECT_MAPPER    [DSJournalXMLMapper class]
#define DS_DEFAULT_MAPPING_TYPE     DSJournalObjectXMLMapping

/**
    @enum DSJournalObjectMapping
    @abstract Типы маппинга
 
    @constant DSJournalObjectXMLMapping
        Маппинг в XML-структуры
    @constant DSJournalObjectJSONMapping
        Маппинг в JSON-структуры
 */
typedef NS_ENUM(NSUInteger, DSJournalObjectMapping) {
    DSJournalObjectXMLMapping = 1,
    DSJournalObjectJSONMapping
};

/**
    @protocol DSJournalMappingProtocol
    @author  HuktoDev
    @updated 20.03.2016
    @abstract Реализует интерфейс для мапперов объектов, используемых репортерами
    @discussion
    Каждый маппер обязан реализовывать в себе весь этот интерфейс.
 
    @note Содержит методы для маппинга в NSData следующие классы :
    <ol type="a">
        <li> объект сервиса DSBaseLoggedService </li>
        <li> объект журнала DSJournal </li>
    </ol>
 */
@protocol DSJournalMappingProtocol <NSObject>

@required

+ (NSData*)dataRepresentationForService:(DSBaseLoggedService*)service;
+ (NSData*)dataRepresentationForJournal:(DSJournal*)journal;

@end




