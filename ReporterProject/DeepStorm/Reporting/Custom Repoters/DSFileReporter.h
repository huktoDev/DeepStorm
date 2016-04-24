////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSFileRepoter.h
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
#import "DSJournalMappingProtocol.h"
#import "DSReporting.h"

/**
    <hr>
    @class DSFileReporter
    @author HuktoDev
    @updated 20.03.2016
    @abstract Класс-репортер, выполняющий задачу сохранения репортов в файл
    @discussion
    Порой нужно сохранить репорты в файл, чтобы при следующем  запуске приложения использовать. Или для каких-либо других причин (например, хранение в файле, как в буфере)
    <hr>
 
    @note Возможности класса :
    <ol type="a">
        <li> Сохраняет репорты в файл(ы) </li>
        <li> Можно выбрать тип маппинга (какую структуру данных использовать) </li>
        <li> Запоминает названия файлов и сохраненные данные </li>
        <li> Удаляет все файлы, сохраненные через этот репортер </li>
    </ol>
 */
@interface DSFileReporter : NSObject <DSReporterProtocol>

#pragma mark - Construction
// Создание репортера

+ (instancetype)fileReporterWithMappingType:(DSJournalObjectMapping)mappingType;


#pragma mark - Data File's
// Другая часть интерфейса (запоминает файлы, и возможность удаления файлов)

@property (strong, nonatomic, readonly) NSMutableDictionary <NSString*, NSData*> *fileDataArray;
- (void)removeDataFiles;

@end
