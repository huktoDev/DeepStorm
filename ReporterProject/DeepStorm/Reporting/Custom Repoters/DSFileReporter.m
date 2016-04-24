////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSFileRepoter.m
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

#import "DSFileReporter.h"
#import "DSJournal.h"
#import "DSBaseLoggedService.h"
#import "DSJournalXMLMapper.h"
#import "DSJournalJSONMapper.h"

#define DS_FILE_EXTENSION_XML   @".xml"
#define DS_FILE_EXTENSION_JSON  @".json"


@implementation DSFileReporter{
    Class<DSJournalMappingProtocol> objectMapperClass;
    DSJournalObjectMapping mapType;
}

@synthesize fileDataArray;

/// Кроме всего назначает дефолтный маппер
- (instancetype)init{
    if(self = [super init]){
        fileDataArray = [NSMutableDictionary new];
        objectMapperClass = DS_DEFAULT_OBJECT_MAPPER;
        mapType = DS_DEFAULT_MAPPING_TYPE;
    }
    return self;
}

/**
    @abstract Инициализатор с типом маппинга
    @discussion
    Иногда нужно установить конкретный тип маппинга.
    @see
    DSJournalObjectMapping
 
    @throw unknownMappingException
         Если тип маппинга нераспознан
 
    @param mappingType       Тип маппинга, который требуется установить
    @return Готовый объект DSFileReporter-а
 */
- (instancetype)initWithMappingType:(DSJournalObjectMapping)mappingType{
    
    if(mappingType < DSJournalObjectXMLMapping && mappingType > DSJournalObjectJSONMapping){
        
        @throw [NSException exceptionWithName:@"unknownMappingException" reason:@"mapping type DSJournalObjectMapping is not recognized" userInfo:nil];
    }
    
    if(self = [self init]){
        switch (mappingType) {
            case DSJournalObjectXMLMapping:
                objectMapperClass = [DSJournalXMLMapper class];
                break;
            case DSJournalObjectJSONMapping:
                objectMapperClass = [DSJournalJSONMapper class];
                break;
            default:
                break;
        }
        mapType = mappingType;
    }
    return self;
}

/**
    @abstract Конструктор репортера с типом маппинга
    @discussion
    Публичный статический метод для получения репортера
    
    @throw unknownMappingException
        Если тип маппинга нераспознан, или расширение не определено
 
    @param mappingType      тип маппинга
    @return Готовый объект DSFileReporter-а
 */
+ (instancetype)fileReporterWithMappingType:(DSJournalObjectMapping)mappingType{
    
    DSFileReporter *fileReporter = [[DSFileReporter alloc] initWithMappingType:mappingType];
    return fileReporter;
}

- (NSString*)reportFileExtension{
    switch (mapType) {
        case DSJournalObjectXMLMapping:
            return DS_FILE_EXTENSION_XML;
        case DSJournalObjectJSONMapping:
            return DS_FILE_EXTENSION_JSON;
        default:
            @throw [NSException exceptionWithName:@"unknownMappingType" reason:@"reportFileExtension is undefined" userInfo:nil];
    }
}

/**
    @abstract Отсылает репорт для определенного журнала
    @discussion
 
    @note Последовательность выполнения :
    <ol type="1">
        <li> Получает NSData данные журнала </li>
        <li> Формирует имя файла журнала (добавляет расширение файла). </li>
        <li> Если журнал  не имеет имя - присваивает ему специфическое имя. </li>
        <li> Если файл существует - удаляет его. </li>
        <li> Сохраняет данные в файл </li>
    </ol>
 
    @param reportingJournal      Журнал, для которого нужно отправить репорт
 */
- (void)sendReportJournal:(DSJournal *)reportingJournal{
    
    // Получить данные журнала
    NSData *journalData = [objectMapperClass dataRepresentationForJournal:reportingJournal];
    
    // Сформировать путь к результирующему файлу
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *currentJournalName = reportingJournal.journalName;
    if(currentJournalName){
        
        // Добавить расширение к имени журнала
        NSString *fileExtension = [self reportFileExtension];
        currentJournalName = [currentJournalName stringByAppendingString:fileExtension];
    }
    
    // Если у журнала нет имени - задать журналу специальное имя
    if(! currentJournalName){
        
        NSString *unknownJournalName;
        BOOL defineJournalName = NO;
        for (NSUInteger indexUndefinedJournal = 1; indexUndefinedJournal <= 100; indexUndefinedJournal ++) {
            
            NSString *fileExtension = [self reportFileExtension];
            unknownJournalName = [NSString stringWithFormat:@"unknownJournal%lu%@", (unsigned long)indexUndefinedJournal, fileExtension];
            NSString *pathToUnknownJournal = [documentsDirectory stringByAppendingPathComponent:unknownJournalName];
            
            BOOL unknownJournalExist = [[NSFileManager defaultManager] fileExistsAtPath:pathToUnknownJournal];
            if(! unknownJournalExist){
                defineJournalName = YES;
                break;
            }
        }
        
        if(defineJournalName){
            currentJournalName = unknownJournalName;
        }
    }
    
    // Если журналу не удалось определить имя
    if(! currentJournalName){
        return;
    }
    
    [fileDataArray setObject:journalData forKey:currentJournalName];
    NSString *currentJournalFile = [documentsDirectory stringByAppendingPathComponent:currentJournalName];
    
    // Удалить файл, если он уже существует
    if([[NSFileManager defaultManager] fileExistsAtPath:currentJournalFile]){
        NSError *deletingError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:currentJournalFile error:&deletingError];
        if(deletingError){
            NSLog(@"Delete File Error %@", [deletingError localizedDescription]);
            return;
        }
    }
    
    // Создать файл, и записать в него данные
    [journalData writeToFile:currentJournalFile atomically:YES];
    
    NSString *dataString = [[NSString alloc] initWithData:journalData encoding:NSUTF8StringEncoding];
    NSLog(@"RESULT DOCUMENT : %@", dataString);
}


/**
    @abstract Отсылает репорт для определенного сервиса
    @discussion
 
    @note Последовательность выполнения :
    <ol type="1">
        <li> Получает NSData данные сервиса </li>
        <li> Формирует имя файла сервиса (добавляет расширение файла). </li>
        <li> Если сервис не имеет имя - присваивает ему специфическое имя. </li>
        <li> Если файл существует - удаляет его. </li>
        <li> Сохраняет данные в файл </li>
    </ol>
 
    @param reportingService      Сервис, для которого нужно отправить репорт
 */
- (void)sendReportService:(DSBaseLoggedService *)reportingService{
    
    // Получить данные сервиса
    NSData *serviceData = [objectMapperClass dataRepresentationForService:reportingService];
    NSString *currentJournalName = reportingService.logJournal.journalName;
    if(! currentJournalName){
        return;
    }
    
    // Сформировать путь к результирующему файлу
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Добавить расширение к имени журнала
    NSString *fileExtension = [self reportFileExtension];
    currentJournalName = [currentJournalName stringByAppendingString:fileExtension];
    [fileDataArray setObject:serviceData forKey:currentJournalName];
    NSString *currentJournalFile = [documentsDirectory stringByAppendingPathComponent:currentJournalName];
    
    // Удалить файл, если он уже существует
    if([[NSFileManager defaultManager] fileExistsAtPath:currentJournalFile]){
        NSError *deletingError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:currentJournalFile error:&deletingError];
        if(deletingError){
            NSLog(@"Delete File Error %@", [deletingError localizedDescription]);
            return;
        }
    }
    
    // Создать файл, и записать в него данные
    [serviceData writeToFile:currentJournalFile atomically:YES];
    
    NSString *dataString = [[NSString alloc] initWithData:serviceData encoding:NSUTF8StringEncoding];
    NSLog(@"RESULT DOCUMENT : %@", dataString);
}

/**
    @abstract Метод удаления файлов, записанных репортером
    @discussion
    Репортеру нужно иметь возможность обратного создания файлу действия (в данном случае - удаления). Кроме того, т.к. DSFileReporter используется в других репортерах, как вспомогательный (данные хранятся в качестве буфера). Позволяет "подтереть" эти временные файлы после  использования.
 
    @throw fileDeletingException
        Исключение при ошибке удаления файла
 */
- (void)removeDataFiles{
    
    BOOL wasFilesSaved = (self.fileDataArray.count != 0);
    NSAssert(wasFilesSaved, @"Try removing Files before Saving");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    for (NSString *fileName in [self.fileDataArray allKeys]) {
        
        NSString *fileResultPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:fileResultPath];
        NSAssert(isFileExists, @"File for Removing is not exist !!!");
        
        NSError *deletingError = nil;
        BOOL isFileDeleted = [[NSFileManager defaultManager] removeItemAtPath:fileResultPath error:&deletingError];
        if(! isFileDeleted || deletingError){
            
            NSString *deletingExceptionReason = [NSString stringWithFormat:@"File Deleting Error : %@", [deletingError localizedDescription]];
            @throw [NSException exceptionWithName:@"fileDeletingException" reason:deletingExceptionReason userInfo:nil];
        }
    }
    [self.fileDataArray removeAllObjects];
}

@end
