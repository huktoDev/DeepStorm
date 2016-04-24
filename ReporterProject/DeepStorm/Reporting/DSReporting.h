////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSReporting.h
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 07.03.16.
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

#ifndef DSReporting_h
#define DSReporting_h

#import <Foundation/Foundation.h>
@class DSJournal, DSBaseLoggedService;

/**
    @protocol DSSimpleReporterProtocol
    @abstract Интерфейс для формирования простых репортов
    @discussion
    Репортер может делать реализацию этого интерфейса, что позволит ему отсылать простые репорты в свой output
 
    @note Протокол обладает 3мя необязательными методами :
    <ol type="1">
        <li> <b> Отправка в конкретный output строкового репорта </b> </li>
        <li> <b> Отправка репорта конкретного журнала </b> </li>
        <li> <b> Отправка репорта конкретного сервиса </b> </li>
    </ol>
 */
@protocol DSSimpleReporterProtocol <NSObject>

@optional
- (void)sendReport:(NSString*)reportString;
- (void)sendReportJournal:(DSJournal*)reportingJournal;
- (void)sendReportService:(DSBaseLoggedService*)reportingService;

@end

/**
    @protocol DSComplexReporterProtocol
    @abstract Интерфейс для формирования комплексных (составных) репортов
    @discussion
    Репортер может делать реализацию этого интерфейса, что позволит ему отсылать сложные репорты в свой output.
    Предполагается, что имеется один большой составной репор, который состоит из более мелких репортов (частей). 
 
    Большой репорт формируется из мелких частей, после чего в определенный момент выполняется его отправка.
    @example  Когда отправляется e-mail - лучше собрать одно большое сообщение (к которому прикрепить все файлы с репортами), чем отправлять много маленьких
 
    @note Протокол обладает 3мя необязательными методами для добавления репорта:
    <ol type="1">
        <li> <b> Добавление строкового репорта</b> </li>
        <li> <b> Добавление репорта конкретного журнала </b> </li>
        <li> <b> Добавление репорта конкретного сервиса </b> </li>
    </ol>
 
    @note Основную задачу выполняет метод отправки подготовленного большого репорта - performAllReports
 */
@protocol DSComplexReporterProtocol <NSObject>

@optional
- (void)addPartReport:(NSString*)reportString;
- (void)addPartReportJournal:(DSJournal*)reportingJournal;
- (void)addPartReportService:(DSBaseLoggedService*)reportingService;

- (void)performAllReports;

@end



/**
    @protocol DSReporterProtocol
    @abstract Протокол, который должен реализовать любой репортер
    @discussion
    У каждого репортера есть выбор - реализовать интерфейс DSSimpleReporterProtocol, или интерфейс DSComplexReporterProtocol.
    Кроме того, можно реализовать оба интерфейса, но при отправке репорта через сервис менеджер- будет в приоритете интерфейс DSComplexReporterProtocol
 
    @note Является результатом множественного наследования интерфейсов 2х видов репортеров
 */
@protocol DSReporterProtocol <DSSimpleReporterProtocol, DSComplexReporterProtocol>

@end


/**
    @protocol DSReportageInterface
    @abstract Интерфейс для осуществления репортажа
    @discussion
    Сервис-менеджер реализует этот интерфейс, чтобы иметь возможность "давать репортажи" о своей жизнедеятельности. Чтобы иметь возможность централизованно вызвать опрос всех подсистем (объектов сервисного слоя)
 */
@protocol DSReportageInterface <NSObject>

@optional
- (void)sendJournalReportageWithReporter:(id<DSReporterProtocol>)reporter;
- (void)sendWorkReportageWithReporter:(id<DSReporterProtocol>)reporter;

@end


#endif /* DSReporting_h */
