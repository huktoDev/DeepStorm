////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSServiceManager.h
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
#import "DSBaseLoggedService.h"
#import "DSReporting.h"


/**
    @protocol DSServiceManagerSubclassingInterface
    @abstract Протокол, который должен определять  каждый подкласс DSServiceManager
 */
@protocol DSServiceManagerSubclassingInterface <NSObject>

@required
- (void)createServices;
- (void)configServices;


@optional

#if DEBUG == 1
- (void)addExperimentalServices;

#endif

@end


@class DSServiceManager;
extern DSServiceManager* SharedServiceManager;


/**
    @typedef DSCreationServices
    @abstract Подвид блока для создания сервисов
 */
/**
    @typedef DSConfigurationServices
    @abstract Подвид блока для конфигурирования сервисов
 */
typedef void (^DSCreationServices)(DSServiceManager*);
typedef void (^DSConfigurationServices)(DSServiceManager*);
typedef void (^DSExperimentServices)(DSServiceManager*);

/**
    @class DSServiceManager
    <hr>
    @author HuktoDev
    @abstract Центральный класс для управления сервисами
    @discussion
    Центр управления сервисами приложения DSBaseLoggedService, центральный объект сервисного слоя. 
    Хранит  в себе сервисы и позволяет раздавать нужные сервисы, является реализацией 
    Dependency Invertor Pattern
    Service Locator Pattern
    <hr>
 
    @note Являет собой нечто вроде "Панели управления"
 
    @note Процесс использования включает в себя 2 этапа :
    <ol type="1">
        <li> Создание и конфигурацию сервисов </li>
        <li> Управление сервисами / Получение сервисов / Создание отчетов </li>
    </ol>
 
    @note В дальнейшем возможно расширение функционала управления пулом сервисов, возможность их группировки и т п
 
    <h4> Имеется 2 способа конфигурирования сервис менеджера :</h4>
    <ol type="1">
        <li> Без порождения подкласса, с помощью блоков (по типу createServicesWithBlock: ) </li>
        <li> С порождением подкласса, и переопределением методов createServices и configServices </li>
    </ol>
    <hr>
 
    @see 
    DSBaseLoggedService \n
    DSReportageInterface \n
    DSJournal \n
    <a href="https://en.wikipedia.org/wiki/Service_locator_pattern"> Sevice Locator </a> \n
    <a href="https://en.wikipedia.org/wiki/Dependency_inversion_principle"> Dependency Inversion </a>
 */
@interface DSServiceManager : DSBaseLoggedService <DSReportageInterface>

// кроме того расшарен в виде глобальной переменной SharedServiceManager
#pragma mark -  Initialization

+ (instancetype)sharedManager;
- (instancetype)initSharedManager NS_DESIGNATED_INITIALIZER;



#pragma mark - SERVICE Store & Recieve
//RU: Получение  конкретного сервиса

/// Пул сервисов приложения
@property (strong, nonatomic) NSMapTable *servicePool;

- (id<DSServiceProtocol>)getSharedService:(NSNumber*)serviceType;
- (void)addServiceToPool:(id<DSServiceProtocol>)service withServiceType:(NSNumber*)serviceType;


#pragma mark - SERVICES ADD FOR SUBCLASS
//RU: Создание и конфигурирования подкласса менеджера

- (void)createServices;
- (void)configServices;

#if DEBUG == 1
- (void)addExperimentalServices;
#endif



#pragma mark - SERVICES ADD WITH BLOCK
//RU: Создание и конфигурирования менеджера с помощью блоков

+ (void)setCreationBlock:(DSCreationServices)creationServicesBlock;
+ (void)setConfigurationBlock:(DSConfigurationServices)configurationServicesBlock;
+ (void)setExperimentalBlock:(DSExperimentServices)experimentalServicesBlock;



#pragma mark - DSReportageInterface
//RU: Отправка репортов

- (void)sendJournalReportageWithReporter:(id<DSReporterProtocol>)reporter;
- (void)sendWorkReportageWithReporter:(id<DSReporterProtocol>)reporter;


#pragma mark - Enumeration Services
//RU: Энумерация сервисов

- (void)enumerateServices:(void (^)(id<DSServiceProtocol>))serviceEnumerationBlock;


#pragma mark - Clear

- (void)clearAllServices;

// disableAllServices
// wipeOffAllServices
// rebootService:
// rebootAllServices

// getSharedService withReciever: // у каждых объектов могут быть разные права на пользование сервисами
// registryServiceInterface: forType: // возможность регистрировать конкретный интерфейс для определенного типа объекта

@end

