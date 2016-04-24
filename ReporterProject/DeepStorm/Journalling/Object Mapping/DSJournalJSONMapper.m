////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournalJSONMapper.m
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

#import "DSJournalJSONMapper.h"
#import "DSJournal.h"
#import "DSBaseLoggedService.h"

@implementation DSJournalJSONMapper

+ (NSData*)dataRepresentationForService:(DSBaseLoggedService*)service{
    
    NSDictionary *serviceRepresentationDict =  [[self class] serviceJSONRepresentation:service];
    
    NSError *serviceError = nil;
    NSData *serviceData = [NSJSONSerialization dataWithJSONObject:serviceRepresentationDict options:NSJSONWritingPrettyPrinted error:&serviceError];
    if(serviceError){
        NSLog(@"SERVICE JSON Representation Error : %@", serviceError);
        return nil;
    }
    
    return serviceData;
}

+ (NSData*)dataRepresentationForJournal:(DSJournal*)journal{
    
    NSDictionary *journalRepresentationDict =  [[self class] journalJSONRepresentation:journal];
    
    NSError *journalError = nil;
    NSData *journalData = [NSJSONSerialization dataWithJSONObject:journalRepresentationDict options:NSJSONWritingPrettyPrinted error:&journalError];
    if(journalError){
        NSLog(@"JOURNAL JSON Representation Error : %@", journalError);
        return nil;
    }
    
    return journalData;
}

+ (NSDictionary*)serviceJSONRepresentation:(DSBaseLoggedService*)service{
    
    NSMutableDictionary *serviceInnerDict = [NSMutableDictionary new];
    
    // Добавить информацию о классе
    NSString *serviceClassString = NSStringFromClass([service class]);
    [serviceInnerDict setObject:serviceClassString forKey:@"class"];
    
    // Добавить информацию о рабочем режиме
    NSString *workingModeDescription = serviceWorkingModeDescription(service.workingMode);
    [serviceInnerDict setObject:workingModeDescription forKey:@"workMode"];
    
    // Добавить ошибки, если таковые возникали в процессе
    if(service.emergencySituationsErrors.count > 0){
        
        NSMutableArray *emergencyArray = [NSMutableArray new];
        for (NSError *emergencyError in service.emergencySituationsErrors) {
            
            NSDictionary *errorDict = [[self class] errorJSONRepresentation:emergencyError];
            [emergencyArray addObject:errorDict];
        }
        [serviceInnerDict setObject:emergencyArray forKey:@"emergencySituations"];
    }
    
    // Добавить информацию  о журнале
    NSDictionary *journalDict = [[self class] journalJSONRepresentation:service.logJournal];
    [serviceInnerDict setObject:journalDict forKey:@"journal"];
    
    NSDictionary *serviceDict = @{@"service" : serviceInnerDict};
    return serviceDict;
}

+ (NSDictionary*)journalJSONRepresentation:(DSJournal*)journal{
    
    // Добавить записи
    NSMutableArray *journalRecordsArray = [NSMutableArray new];
    [journal enumerateRecords:^(DSJournalRecord *journalRecord) {
        
        NSDictionary *recordDictionary = [[self class] recordJSONRepresentation:journalRecord];
        [journalRecordsArray addObject:recordDictionary];
    }];
    
    NSDictionary *journalDict = @{@"journal" : journalRecordsArray};
    return journalDict;
}

+ (NSDictionary*)recordJSONRepresentation:(DSJournalRecord*)record{
    
    // Добавить номер записи
    NSMutableDictionary *recordInnerDict = [NSMutableDictionary new];
    [recordInnerDict setObject:[record.recordNumber stringValue] forKey:@"number"];
    
    // Добавить описание и дату записи
    NSString *dateDescription = [record.recordDate description];
    [recordInnerDict setObject:dateDescription forKey:@"date"];
    [recordInnerDict setObject:record.recordDescription forKey:@"description"];
    
    // Добавить userInfo записи, если есть
    if(record.recordInfo){
        [recordInnerDict setObject:[record.recordInfo description] forKey:@"userInfo"];
    }
    
    NSDictionary *recordDict = @{@"record" : recordInnerDict};
    return recordDict;
}

+ (NSDictionary*)errorJSONRepresentation:(NSError*)error{
    
    NSMutableDictionary *errorInnerDict = [NSMutableDictionary new];
    [errorInnerDict setObject:[error domain] forKey:@"domain"];
    [errorInnerDict setObject:@([error code]) forKey:@"code"];
    if([error localizedDescription]){
        [errorInnerDict setObject:[error localizedDescription] forKey:@"description"];
    }
    if([error localizedFailureReason]){
        [errorInnerDict setObject:[error localizedFailureReason] forKey:@"reason"];
    }
    
    NSDictionary *errorDict = @{@"error" : errorInnerDict};
    return errorDict;
}

@end
