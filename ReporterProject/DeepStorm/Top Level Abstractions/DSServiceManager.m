////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSServiceManager.m
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
#import "DSServiceManager.h"

DSServiceManager *SharedServiceManager = nil;


DSCreationServices creationBlock = nil;
DSConfigurationServices configurationBlock = nil;
DSExperimentServices experimentalBlock = nil;

@implementation DSServiceManager

#pragma mark -  Initialization

+ (instancetype)sharedManager {
    return SharedServiceManager;
}

- (instancetype)init{
    return [self initSharedManager];
}

/**
    @abstract Назначенный конструктор, задающий расшаренный объект SharedServiceManager
    @discussion
    Проверяет подкласс DSServiceManager, если таковой имеется на наличие новой реализации createServices и configServices. Если подкласс определяет реализацию этих  методов - они последовательно вызываются.
    Иначе генерится эксепшен, если подкласс их не реализует.
    
    @note Если используется обычный DSServiceManager, то требуется использовать создание и конфигурацию через createServicesWithBlock:, и запускать их вручную
 
    @throw OverrideManagerException     Генерится, если у подкласса не переопределены требуемые методы
 
    @return Готовый инициализированный менеджер
 */
- (instancetype)initSharedManager{
    if(self = [super init]){
        
        Class baseClass = [DSServiceManager class];
        Class currentClass = [self class];
        SEL createSelector = @selector(createServices);
        SEL configSelector = @selector(configServices);
        
        BOOL isClassRedefined = (currentClass != baseClass);
        if(isClassRedefined){
            
            IMP baseImplementation = [baseClass instanceMethodForSelector:createSelector];
            IMP redefinedImplementation = [currentClass instanceMethodForSelector:createSelector];
            
            BOOL isCreationRedefined = (baseImplementation != redefinedImplementation);
            
            baseImplementation = [baseClass instanceMethodForSelector:configSelector];
            redefinedImplementation = [currentClass instanceMethodForSelector:configSelector];
            
            BOOL isConfigurationRedefined = (baseImplementation != redefinedImplementation);
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if(isCreationRedefined && isConfigurationRedefined){
                
                [self performSelector:createSelector];
                [self performSelector:configSelector];
            }else{
                @throw [NSException exceptionWithName:@"OverrideManagerException" reason:@"Overrided manager must override methods createServices & configServices" userInfo:nil];
            }
#pragma clang diagnostic pop
            
#if DEBUG == 1
            if([self respondsToSelector:@selector(addExperimentalServices)]){
                [self addExperimentalServices];
            }
#endif
        }else{
            
            BOOL haveAllNeededBlocks = (creationBlock != nil) && (configurationBlock != nil);
            NSAssert(haveAllNeededBlocks, @"creationBlock or configurationBlock is need to be added under Initialization");
            
            creationBlock(self);
            configurationBlock(self);
            
#if DEBUG == 1
            if(experimentalBlock){
                experimentalBlock(self);
            }
#endif
        }
        
        SharedServiceManager = self;
    }
    return self;
}

#pragma mark - SERVICE Store & Recieve

/**
    @abstract Получает требуемый расшаренный сервис
    @discussion
    Получает сервис из пула сервисов по  указанному типу. Тип лучше всего иметь в каком-либо перечислении.
    Позволяет централизовать получение любого класса сервисного слоя через этот метод. ( принцип одной точки входа )
 
    @param serviceType      Тип сервиса (числовое значение в NSNumber)
    @return Найденный сервис для данного serviceType, либо nil
 */
- (id<DSServiceProtocol>)getSharedService:(NSNumber*)serviceType{
    
    NSAssert(serviceType, @"Service Type must be not nil");
    NSAssert([serviceType isKindOfClass:[NSNumber class]], @"Service Type must be NSNumber");
    
    id <DSServiceProtocol> associatedService = [self.servicePool objectForKey:serviceType];
    return associatedService;
}

/**
    @abstract Добавляет сервис к пулу сервисов
    @discussion
    Чтобы любой сервис был виден через метод getSharedService:, а также вместе с другими с него автоматически бы собирались репорты,  проводились бы разные иные действия - его нужно добавить в пул сервисов ( с указанием serviceType ) - это будет его ключом. 
    После создания сервисов - имеет смысл добавить их в пул сервисов
 
    @note Кроме того, существует возможность удобно моккировать, заменять объект сервиса на их моки или стабы
 
    @warning Используется отложенная инициализация пула сервисов здесь
 
    @param service      Объект сервиса, добавляемый в пул. Должен определять DSServiceProtocol протокол
    @param serviceType      Тип  сервиса, добавляемого в пул
 */
- (void)addServiceToPool:(id<DSServiceProtocol>)service withServiceType:(NSNumber*)serviceType{
    
    if(! self.servicePool){
        self.servicePool = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    
    NSAssert(service, @"adding Service must be not nil");
    NSAssert(serviceType, @"serviceType ust be not nil");
    
    BOOL isValidService = [service conformsToProtocol:@protocol(DSServiceProtocol)];
    NSAssert(isValidService, @"Service not added to pool : Service isn't Valid! Service Must implement DSServiceProtocol");
    
    [service setServiceType:serviceType];
    [self.servicePool setObject:service forKey:serviceType];
}

#pragma mark - SERVICES ADD FOR SUBCLASS

/**
    @abstract Метод создания сервисов
    @discussion
    Используется, как место инициализации сервисов. Здесь нужно выполнять создание объектов сервисов, здесь можно добавлять их к сервисному пулу
 
    @throw AbstractMethodException      Генерится у подкласса, если метод не переопределен
    @warning Абстрактный метод! Этот метод требуется переопределить
 */
- (void)createServices{
    if([self class] == [DSServiceManager class]){
        @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Not define subclass for use this method - createServices" userInfo:nil];
    }
}

/**
    @abstract Метод конфигурирования сервисов
    @discussion
    Используется, как место конфигурирования сервисов. Здесь можно запускать у сервисов конфигураторы, а также заниматься Dependency Injection (инъекцией зависимостей). Если ранее сервис не был добавлен к сервисному пулу - его можно добавить здесь.
 
    @throw AbstractMethodException      Генерится у подкласса, если метод не переопределен
    @warning Абстрактный метод! Этот метод требуется переопределить
 */
- (void)configServices{
    if([self class] == [DSServiceManager class]){
        @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Not define subclass for use this method - configServices" userInfo:nil];
    }
}

/**
    @abstract Метод для экспериментов с сервисами (только на дебаге)
    @discussion
    Можно использовать, как безопасное место для различных эмуляций, тестов, использования экспериментальных (недописанных сервисов).
 
    @throw AbstractMethodException      Генерится у подкласса, если метод не переопределен
    @warning Абстрактный метод! Этот метод требуется переопределить. 
 
    @note Не обязательно переопределять, метод опционален для подкласса
 */
#if DEBUG == 1
- (void)addExperimentalServices{
    if([self class] == [DSServiceManager class]){
        @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Not define subclass for use this method - addExperimentalServices" userInfo:nil];
    }
}
#endif


#pragma mark - SERVICES ADD WITH BLOCK

/**
    @abstract Метод создания сервисов с помощью блока
    @discussion
    Используется, как место инициализации сервисов. Здесь нужно выполнять создание объектов сервисов, здесь можно добавлять их к сервисному пулу
 
    @note Важно вызывать их именно перед инициализацией менеджера
 
    @param creationServicesBlock      Блок, в котором выполняется создание сервисов
 */
+ (void)setCreationBlock:(DSCreationServices)creationServicesBlock{
    
    NSAssert(SharedServiceManager == nil, @"%@ must be under Service Initialization", NSStringFromSelector(_cmd));
    creationBlock = [creationServicesBlock copy];
}

/**
    @abstract Метод конфигурирования сервисов с помощью блока
    @discussion
    Используется, как место конфигурирования сервисов. Здесь можно запускать у сервисов конфигураторы, а также заниматься Dependency Injection (инъекцией зависимостей). Если ранее сервис не был добавлен к сервисному пулу - его можно добавить здесь.
 
    @note Важно вызывать их именно перед инициализацией менеджера
 
    @param configurationServicesBlock      Блок, в котором выполняется конфигурирование сервисов
 */
+ (void)setConfigurationBlock:(DSConfigurationServices)configurationServicesBlock{
    
    NSAssert(SharedServiceManager == nil, @"%@ must be under Service Initialization", NSStringFromSelector(_cmd));
    configurationBlock = [configurationServicesBlock copy];
}

/**
    @abstract Метод для экспериментирования с сервисами с помощью блока
    @discussion
    Используется в качестве места для экспериментирования с сервисами, различных тестов и эмуляций (обычно требуется выполнять после создания и конфигурирования остальных сервисов)
 
    @note Важно вызывать их именно перед инициализацией менеджера
 
    @param experimentalServicesBlock      Блок, в котором выполняются описанные выше эксперименты
 */
+ (void)setExperimentalBlock:(DSExperimentServices)experimentalServicesBlock{
    
    NSAssert(SharedServiceManager == nil, @"%@ must be under Service Initialization", NSStringFromSelector(_cmd));
    
#if DEBUG == 1
    experimentalServicesBlock = [experimentalServicesBlock copy];
#endif
}


#pragma mark - DSReportageInterface

/**
    @abstract Отослать полную информацию о всех журналах
    @discussion
    Позволяет собрать информацию о всех журналах сервисов данного сервис-менеджера. И передать эту информацию соответствующему репортеру.
    Возможно 2 типа отправки репортов :
    <ol type="1">
        <li> Если переданный reporter позволяет - сначала собрать информацию с помощью addPartReportJournal, после чего в конце отправить ее по назначению с помощью performAllReports </li>
        <li> Для обычных репортеров - просто отсылается N отчетов, где N - число сервисов </li>
    </ol>
 
    @note Класс сервис-менеджера тоже считается за сервис
    
    @param reporter     Объект-репортера, который осуществляет "репортаж" системы
 */
- (void)sendJournalReportageWithReporter:(id<DSReporterProtocol>)reporter{
    
    // Если используется, например, EmailReporter - стоит упорядочивать по несколько файлов в одном имейле
    if([reporter respondsToSelector:@selector(performAllReports)]){
        
        SEL addPartSelector = @selector(addPartReportJournal:);
        BOOL reporterPrepared = [reporter respondsToSelector:addPartSelector];
        NSAssert(reporterPrepared, @"reporter Not defined Method %@", NSStringFromSelector(addPartSelector));
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        [reporter performSelector:addPartSelector withObject:self.logJournal];
        
        [self enumerateServices:^(id<DSServiceProtocol> currentService) {
            if(currentService.logJournal){
                [reporter performSelector:addPartSelector withObject:currentService.logJournal];
            }
        }];
#pragma clang diagnostic pop
        
        [reporter performAllReports];
        
    }else{
        [self sendServiceJournalReport:reporter];
        
        [self enumerateServices:^(id<DSServiceProtocol> currentService) {
            [currentService sendServiceJournalReport:reporter];
        }];
    }
}

/**
    @abstract Отослать полную информацию о работе всего сервисного слоя
    @discussion
    Позволяет собрать всю информацию обо всех сервисах данного сервис-менеджера. И передать эту информацию соответствующему репортеру.
    Возможно 2 типа отправки репортов :
    <ol type="1">
        <li> Если переданный reporter позволяет - сначала собрать информацию с помощью addPartReportJournal, после чего в конце отправить ее по назначению с помощью performAllReports </li>
        <li> Для обычных репортеров - просто отсылается N отчетов, где N - число сервисов </li>
    </ol>
 
    @note Класс сервис-менеджера тоже считается за сервис
 
    @param reporter     Объект-репортера, который осуществляет "репортаж" системы
 */
- (void)sendWorkReportageWithReporter:(id<DSReporterProtocol>)reporter{
    
    if([reporter respondsToSelector:@selector(performAllReports)]){
        
        SEL addPartSelector = @selector(addPartReportService:);
        BOOL reporterPrepared = [reporter respondsToSelector:addPartSelector];
        NSAssert(reporterPrepared, @"reporter Not defined Method %@", NSStringFromSelector(addPartSelector));
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        [reporter performSelector:addPartSelector withObject:self];
        [self enumerateServices:^(id<DSServiceProtocol> currentService) {
            [reporter performSelector:addPartSelector withObject:currentService];
        }];
        
#pragma clang diagnostic pop
        
        [reporter performAllReports];
        
    }else{
        [self sendServiceWorkReport:reporter];
        [self enumerateServices:^(id<DSServiceProtocol> currentService) {
            [currentService sendServiceWorkReport:reporter];
        }];
    }
}

#pragma mark - Enumeration Services

/**
    @abstract Метод, выполняющий энумерацию сервисов
    @discussion
    С помощью этого метода можно выполнять перечисление имеющихся сервисов приложения
 
    @note Энумерация выполняется потоко-безопасно
 
    @param serviceEnumerationBlock      Блок, в который передается сервис на каждой итерации
 */
- (void)enumerateServices:(void (^)(id<DSServiceProtocol>))serviceEnumerationBlock{
    
    @synchronized(self.servicePool) {
        
        NSEnumerator *serviceEnumerator = [self.servicePool objectEnumerator];
        id <DSServiceProtocol> currentService = nil;
        while (currentService = [serviceEnumerator nextObject]) {
            
            serviceEnumerationBlock(currentService);
        }
    }
}

#pragma mark - Clear

/// Позволяет почистить журналы всех сервисов
- (void)clearAllServices{
    
    [self enumerateServices:^(id<DSServiceProtocol> currentService) {
        
        if([currentService respondsToSelector:@selector(clearJournal)]){
            [currentService clearJournal];
        }
    }];
}


@end
