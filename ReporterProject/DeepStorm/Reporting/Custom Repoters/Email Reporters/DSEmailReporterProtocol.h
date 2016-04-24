////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSEmailReporterProtocol.h
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

/**
    @protocol DSEmailReporterProtocol
    @abstract Общий интерфейс для Email Reporter-ов
    @discussion
    Вполне очевидно, что каждый имейл репортер должен определять выбор адреса имейла назначения. 
    Кроме того, имейл репорты должен иметь метод/методы отправки данных.
 
    @note Иногда нужно иметь возможность выбрать форматирование/тип структуры данных репорта
 */
@protocol DSEmailReporterProtocol <NSObject>

@required

- (void)addDestinationEmail:(NSString*)destinationEmail;

- (void)sendEmailWithData:(NSData*)emailData withFilename:(NSString*)fileName;
- (void)sendEmailWithFileArray:(NSDictionary <NSString*, NSData*> *)filesDictionary;

@optional

- (void)setMappingType:(DSJournalObjectMapping)mappingType;


@end
