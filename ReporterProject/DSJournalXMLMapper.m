////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournalXMLMapper.m
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 28.02.16.
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
#import "DSJournalXMLMapper.h"
#import "DSJournal.h"
#import "DSBaseLoggedService.h"

@implementation DSJournalXMLMapper

+ (NSData*)dataRepresentationForService:(DSBaseLoggedService*)service{
    
    GDataXMLElement *serviceElement = [[self class] serviceXMLRepresentation:service];
    GDataXMLDocument *xmlDocument = [[GDataXMLDocument alloc] initWithRootElement:serviceElement];
    NSData *serviceXMLData = [xmlDocument XMLData];
    
    return serviceXMLData;
}

+ (NSData*)dataRepresentationForJournal:(DSJournal*)journal{
    
    GDataXMLElement *journalElement = [[self class] journalXMLRepresentation:journal];
    GDataXMLDocument *xmlDocument = [[GDataXMLDocument alloc] initWithRootElement:journalElement];
    NSData *journalXMLData = [xmlDocument XMLData];
    
    return journalXMLData;
}

+ (GDataXMLElement*)serviceXMLRepresentation:(DSBaseLoggedService*)service{
    
    // Создать корневой XML-элемент
    GDataXMLElement *serviceElement = [GDataXMLNode elementWithName:@"service"];
    NSString *serviceClassString = NSStringFromClass([service class]);
    id serviceClassAtribute = [GDataXMLNode attributeWithName:@"class" stringValue:serviceClassString];
    [serviceElement addAttribute:serviceClassAtribute];
    
    // Добавить аттрибут workMode
    NSString *workingModeDescription = serviceWorkingModeDescription(service.workingMode);
    GDataXMLElement *workModeElement = [GDataXMLNode elementWithName:@"workMode" stringValue:workingModeDescription];
    [serviceElement addChild:workModeElement];
    
    // Добавить тэг emergencySituations
    if(service.emergencySituationsErrors.count > 0){
        
        GDataXMLElement *emergencyElement = [GDataXMLNode elementWithName:@"emergencySituations"];
        for (NSError *emergencyError in service.emergencySituationsErrors) {
            
            GDataXMLElement *errorElement = [[self class] errorXMLRepresentation:emergencyError];
            [emergencyElement addChild:errorElement];
        }
        [serviceElement addChild:emergencyElement];
    }
    
    GDataXMLElement *journalElement = [[self class] journalXMLRepresentation:service.logJournal];
    [serviceElement addChild:journalElement];
    
    return serviceElement;
}

+ (GDataXMLElement*)journalXMLRepresentation:(DSJournal*)journal{
    
    GDataXMLElement *journalElement = [GDataXMLElement elementWithName:@"journal"];
    [journal enumerateRecords:^(DSJournalRecord *journalRecord) {
        
        GDataXMLElement *recordElement = [[self class] recordXMLRepresentation:journalRecord];
        [journalElement addChild:recordElement];
    }];
    return journalElement;
}

+ (GDataXMLElement*)recordXMLRepresentation:(DSJournalRecord*)record{
    
    GDataXMLElement *recordElement = [GDataXMLNode elementWithName:@"record"];
    id recordNumberAtribute = [GDataXMLNode attributeWithName:@"number" stringValue:[record.recordNumber stringValue]];
    [recordElement addAttribute:recordNumberAtribute];
    
    NSString *dateDescription = [record.recordDate description];
    GDataXMLElement *dateElement = [GDataXMLNode elementWithName:@"date" stringValue:dateDescription];
    [recordElement addChild:dateElement];
    
    GDataXMLElement *descriptionElement = [GDataXMLNode elementWithName:@"description" stringValue:record.recordDescription];
    [recordElement addChild:descriptionElement];
    
    if(record.recordInfo){
        
        GDataXMLElement *infoElement = [GDataXMLNode elementWithName:@"userInfo" stringValue:[record.recordInfo description]];
        [recordElement addChild:infoElement];
    }
    return recordElement;
}

+ (GDataXMLElement*)errorXMLRepresentation:(NSError*)error{
    
    GDataXMLElement *errorElement = [GDataXMLNode elementWithName:@"error"];
    
    GDataXMLElement *errorDomainElement = [GDataXMLNode elementWithName:@"domain" stringValue:[error domain]];
    [errorElement addChild:errorDomainElement];
    
    GDataXMLElement *errorCodeElement = [GDataXMLNode elementWithName:@"code" stringValue:[@([error code]) stringValue]];
    [errorElement addChild:errorCodeElement];
    
    if([error localizedDescription]){
        
        GDataXMLElement *errorDescriptionElement = [GDataXMLNode elementWithName:@"description" stringValue:[error localizedDescription]];
        [errorElement addChild:errorDescriptionElement];
    }
    
    if([error localizedFailureReason]){
        
        GDataXMLElement *errorReasonElement = [GDataXMLNode elementWithName:@"reason" stringValue:[error localizedFailureReason]];
        [errorElement addChild:errorReasonElement];
    }
    return errorElement;
}

@end
