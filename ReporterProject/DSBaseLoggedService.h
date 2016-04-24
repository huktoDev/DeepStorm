////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSBaseLoggedService.h
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
#import "DSReporting.h"
#import "DSOutputConsoleReporter.h"

/**
    @enum DSServiceWorkingMode
    @abstract Режимы работы сервиса
    
    @constant DSServiceNormalWork
        Сервис нормально функционирует
    @constant DSServiceLightError
        Сервис функционирует, но некорректно. Возможны поломки и смерть объекта
    @constant DSServiceCriticalError
        В работе сервиса произошла критическая ошибка!
 */
typedef NS_ENUM(NSUInteger, DSServiceWorkingMode) {
    DSServiceNormalWork = 0,
    DSServiceLightError,
    DSServiceCriticalError,
};

/**
    @function serviceWorkingModeDescription(DSServiceWorkingMode*)
        Возвращает строковое описание переданного режимаа работы сервиса
    @def SERVICE_WORKING_MODE
        Возвращает строкове описание рабочего режима данного сервиса
 */
NSString *serviceWorkingModeDescription(DSServiceWorkingMode workingMode);
#define SERVICE_WORKING_MODE serviceWorkingModeDescription(self.workingMode)


/**
    @protocol DSServiceWorkingProtocol
    @abstract Интерфейс для рабочих отчетов
    @discussion
    Интерфейс, определяемый сервисом для рабочих отчетов, и определения функционирования. 
    <ul>
        <li> Для каждого сервиса можно сделать так, чтобы была возможность оповестить о текущем режиме работы </li>
        <li> Сервис может сохранять ошибки, которые в нем происходят, менять соответствующим образом режим </li>
        <li> Сервис должен уметь создавать отчет о своей рабочей деятельности </li>
    </ul>
 
    @property workingMode       Текущий рабочий режим сервиса
    @property emergencySituationsErrors         Ошибки и аварии, которые происходили с сервисом
    
    @method fixateEmergercySituationWithError:          Добавляем информацию о произошедшей аварии/ошибке
    @method changeWorkingMode:          Удобный сэттер для рабочего режима
    @method sendServiceWorkReport:          Метод для рабочего репорта сервиса (по сути основной метод, из-за которого вся каша)
 */
@protocol DSServiceWorkingProtocol <NSObject>

@required

@property (assign, atomic) DSServiceWorkingMode workingMode;
@property (strong, atomic) NSMutableArray <NSError*> *emergencySituationsErrors;

- (void)fixateEmergercySituationWithError:(NSError*)emergencyError;
- (void)changeWorkingMode:(DSServiceWorkingMode)workingMode;

- (void)sendServiceWorkReport:(id<DSReporterProtocol>)customReporter;

@end

/**
    @protocol DSServiceLoggingProtocol
    @abstract Интерфейс для логгирования сервиса
    @discussion
    Дает сервису интерфейс для сохранения истории собственной жизнедеятельности. (механизм журналирования)
    
    @property logJournal Экземпляр журнала, где будут "складироваться" записи
 
    @method log:        Метод для добавления новой записи
    @method log: withInfo:          Метод для добалени новой записи с прикрепленным словарем
    @method clearJournal           Метод очистки журнала
    @method sendServiceJournalReport:           Метод для репорта истории сервиса
 */
@protocol DSServiceLoggingProtocol <NSObject>

@required

@property (strong, nonatomic) DSJournal *logJournal;
- (void)log:(NSString*)logString;
- (void)log:(NSString*)logString withInfo:(NSDictionary*)userInfo;
- (void)clearJournal;

- (void)sendServiceJournalReport:(id<DSReporterProtocol>)customReporter;

@end

/**
    @protocol DSServiceProtocol
    @abstract Объединенный протокол для определения основного интерфейса сервиса
    @discussion
    Содержит в себе 2 разграниченных интерфейса - 
    <ol type="a">
        <li> Интерфейс для определения рабочего состояния и режима - DSServiceWorkingProtocol </li>
        <li> Интерфейс для работы с "историей" - DSServiceLoggingProtocol </li>
    </ol>
 
    @note Так-же содержит возможность уникальной идентификации сервиса
 */
@protocol DSServiceProtocol <DSServiceWorkingProtocol, DSServiceLoggingProtocol>

@required
@property (copy, nonatomic) NSNumber *serviceType;

@end

// TODO: Сервис должен иметь репортера, которому будет отправлять ответы
// TODO: CrashHandler должен собирать  информацию с системы, и отправлять ее куда требуется

// Есть 2 случая, когда система может затребовать репорт - 1) Когда программист самостоятельно через lldb, удаленно или в коде инициирует получение репорта : В таком случае ему будет полезнее обычный - (NSString*)serviceReport; , иногда - (NSString*)serviceReportWithFullReporting:(BOOL)needFullReporting;

// 2й случай - когда системе требуется сформировать файл, содержащий полную информацию о сервисе - в таком случае сервис передается аргументом в специальную фабрику, и  она самостоятельно собирает


@interface DSBaseLoggedService : NSObject <DSServiceProtocol>

@property (strong, nonatomic) id<DSReporterProtocol> baseLogRepoter;
// OutputConsoleReporter содержит информацию о 1) full reporting 2) format description

#pragma mark - WORK WIH SERVICE LOGS
// Работа с серверными логами

- (void)log:(NSString*)logString;
- (void)log:(NSString*)logString withInfo:(NSDictionary*)userInfo;
- (void)clearJournal;


#pragma mark - Simple Journal Reports
// Получение простых репортов журнала (без отправки)

- (NSString*)serviceJournalReportWithFormatDescription:(DSJournalFormatDescription)formatDescription;
- (NSString*)serviceExtendedRecordForNumber:(NSNumber*)recordNumber withFormatDescription:(DSJournalFormatDescription)formatDescription;


#pragma mark - Simple Work Reports
// Получение простых рабочих репортов (без отправки)

- (NSString*)serviceReport;
- (NSString*)serviceReportWithFullReporting:(BOOL)needFullReporting;


#pragma mark - Send Reports
// Отправка самых различных репортов

- (void)sendBaseServiceJournalReport;
- (void)sendServiceJournalReport:(id<DSReporterProtocol>)customReporter;

- (void)sendBaseServiceWorkReport;
- (void)sendServiceWorkReport:(id<DSReporterProtocol>)customReporter;


@end