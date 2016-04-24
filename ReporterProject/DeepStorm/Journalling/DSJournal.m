////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournal.m
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
#import "DSJournal.h"
#import "DSJournalDefines.h"

@implementation DSJournalRecord

#pragma mark - Description Records With Formatting

/// Короткое описание записи журнала
- (NSString*)shortTypeDescription{
    
    NSString *recordShortDescription = [NSString stringWithFormat:@"%@. [%@] %@", self.recordNumber, self.recordDate, self.recordDescription];
    if(self.recordInfo){
        recordShortDescription = [recordShortDescription stringByAppendingFormat:@" (INFO : %@)", self.recordInfo];
    }
    return recordShortDescription;
}

/// Расширенное описане записи журнала
- (NSString*)extendedTypeDescription{
    
    return [NSString stringWithFormat:@"Record %@ :\nTime Record : %@\nRecord Description : %@\nRecord Info : \n%@", self.recordNumber, self.recordDate, self.recordDescription, self.recordInfo];
}

/// Описание записи журнала по выбранному типу форматирования
- (NSString*)descriptionWithFormat:(DSJournalFormatDescription)descriptionFormat{
    
    if(descriptionFormat == DSJournalShortDescription){
        return [self shortTypeDescription];
    }else if(descriptionFormat == DSJournalExtendedDescription){
        return [self extendedTypeDescription];
    }else{
        return nil;
    }
}

@end


@implementation DSJournal

#pragma mark - Config Journal

- (instancetype)init{
    if(self = [super init]){
        
        self.maxCountStoredRecords = DEFAULT_MAX_STORED_RECORDS;
        records = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Manipulate Records

/**
    @abstract Добавление новой записи в журнал
    @discussion
    Создает новую запись из переданной информации, затем синхронизированно добавляет в журнал
    Присваивает записи идентификатор (порядковый номер)
 
    @note Если включен в коде режим потокового логгирования DSJOURNAL_LOG_STREAMING - логгирует записи в консоль сразу при добавлении (еще требуется, чтобы outputLoggingDisabled = NO )
    
    @note Если записей становится слишком много - очищает записи порциями
 
    @param logString        Логгируемая строка (содержащая описание записи)
    @param userInfo         Дополнительная информация к записи (словарь)
 */
- (void)addLogRecord:(nonnull NSString*)logString withInfo:(nullable NSDictionary*)userInfo {
    
    DSJournalRecord *newRecord = [DSJournalRecord new];
    newRecord.recordDescription = logString;
    newRecord.recordDate = [NSDate date];
    newRecord.recordInfo = userInfo;
    
    @synchronized(records) {
        
        // Присваивает записи порядковый номер
        DSJournalRecord *lastRecord = [records lastObject];
        NSUInteger newRecordNumber = lastRecord ? ([lastRecord.recordNumber unsignedIntegerValue] + 1) : 1;
        newRecord.recordNumber = @(newRecordNumber);
        
        //очищает записи порциями
        if(records.count >= self.maxCountStoredRecords){
            [records removeObjectsInRange:NSMakeRange(0, 100)];
        }
        [records addObject:newRecord];
    }
    
#if DSJOURNAL_LOG_STREAMING == 1
    
    // Если не отключено потоковое логгирование - вывести запись в консоль
    if(! self.outputLoggingDisabled){
        
        NSString *recordDescription = [newRecord shortTypeDescription];
        DSLOGGER_STREAM_MACRO(@"%@", recordDescription);
    }
#endif
}

/**
    @abstract Добавление  новой отформатированной записи в журнал
    @discussion
    Часто нужно более упрощенный способ добавить запись к журналу. Чтобы не создавать строку сначала, а только потом логгировать. Чтобы можно было формат и параметры формата передать в методе
 
    @param userInfo         Дополнительная информация к записи (словарь)
    @param format         Строка форматирования, далее к ней крепятся последовательность параметров. Результирующая строка будет добавлена в журнал
 */
- (void)addLogWithInfo:(NSDictionary*)userInfo withFormat:(NSString*)format, ...{
    
    if(format){
        va_list argsList;
        va_start(argsList, format);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
        NSString *formattedLogMessage = [[NSString alloc] initWithFormat:format arguments:argsList];
#pragma clang diagnostic pop
        
        va_end(argsList);
        [self addLogRecord:formattedLogMessage withInfo:userInfo];
        
    }else{
        NSLog(@"Format Can Not be NIL !");
    }
}

/// Безопасно очищает журнал (удаляет все записи)
- (void)clearJournal{
    @synchronized(records) {
        [records removeAllObjects];
    }
}

#pragma mark - Create Reports

/**
    @abstract Получает строковое представления журнала
    @discussion
    Формирует строковое представление журнала с представлениями записей в выбранном формате.
    Собирает описания всех записей, и компонует их
 
    @param descriptionFormat Формат описания записей журнал
    @return Строка-описание журнала
 */
- (NSString*)getJournalWithFormatDescription:(DSJournalFormatDescription)descriptionFormat{
    
    NSMutableString *bigJournalString = [NSMutableString new];
    [self enumerateRecords:^(DSJournalRecord *logRecord) {
        
        [bigJournalString appendFormat:@"%@\n", [logRecord descriptionWithFormat:descriptionFormat]];
    }];
    return bigJournalString;
}

/**
    @abstract Получает строковое представления журнала последних n записей журнала
    @discussion
    Формирует строковое представление журнала с представлениями записей в выбранном формате.
    Собирает описания последних  countNeededRecords записей, и компонует их
 
    @param countNeededRecords       Количество требуемых последних записей
    @param descriptionFormat        Формат описания записей журнал
    @return Строка-описание         журнала
 */
- (NSString*)getJournalLastRecords:(NSUInteger)countNeededRecords WithFormatDescription:(DSJournalFormatDescription)descriptionFormat{
    
    NSMutableString *bigJournalString = [NSMutableString new];
    [self enumerateLast:countNeededRecords records:^(DSJournalRecord *logRecord) {
        
        [bigJournalString appendFormat:@"%@\n", [logRecord descriptionWithFormat:descriptionFormat]];
    }];
    return bigJournalString;
}

/**
    @abstract Получает описание для конкретной записи
    @discussion
    Сначала получает конкретную запись по порядковому номеру записи.
    Потом для этой записи получает описание по требуемому формату
 
    @note Если запись не найдена - возвращает  nil
 
    @param numberRecord Порядковый номер записи
    @param descriptionFormat Формт описания записи
 
    @return Строка, описывающая запись (nil, если запись не найдена)
 */
- (NSString*)getDescriptionRecord:(NSNumber*)numberRecord withFormatDescription:(DSJournalFormatDescription)descriptionFormat{
    
    DSJournalRecord *record = [self getRecordWithNumber:numberRecord];
    if(record){
        return [record descriptionWithFormat:descriptionFormat];
    }else{
        return nil;
    }
}

#pragma mark - Recieving Records

/// Получение записи по порядковому номеру (nil, если не найдена)
- (DSJournalRecord*)getRecordWithNumber:(NSNumber*)numberRecord{
    for (DSJournalRecord *logRecord in records) {
        if([logRecord.recordNumber isEqualToNumber:numberRecord]){
            return logRecord;
        }
    }
    return nil;
}

/// Энумерация всех записей в журнале с помощью блока
- (void)enumerateRecords:(void (^)(DSJournalRecord *))recordEnumerateBlock{
    
    @synchronized(records) {
        for (DSJournalRecord *currentRecord in records) {
            recordEnumerateBlock(currentRecord);
        }
    }
}

- (void)enumerateLast:(NSUInteger)countNeededRecords records:(void (^)(DSJournalRecord *))recordEnumerateBlock{
    
    @synchronized(records) {
        
        NSUInteger countLastRecords = (countNeededRecords <= records.count) ? countNeededRecords : records.count;
        NSArray <DSJournalRecord*> *croppedRecords = [records subarrayWithRange:NSMakeRange(records.count - countLastRecords, countLastRecords)];
        for (DSJournalRecord *currentRecord in croppedRecords) {
            recordEnumerateBlock(currentRecord);
        }
    }
}

@end
