////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSEmailReporter.m
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
#import "DSEmailReporter.h"
#import "DSJournalXMLMapper.h"
#import "DSBaseLoggedService.h"
#import "DSJournal.h"
#import "UIWindow+DSControllerDetermination.h"
#import "NSString+DSEmailValidation.h"
#import "DSFileReporter.h"

@import MessageUI;

@interface DSEmailReporter () <MFMailComposeViewControllerDelegate>

@end

@implementation DSEmailReporter{
    
    NSString *destinationAddress;
    
    DSFileReporter *internalFileReporter;
    DSFileReporter *helpfulFileReporter;
    
    DSJournalObjectMapping mapType;
}

#pragma mark - Initialization

- (instancetype)init{
    if(self = [super init]){
        mapType = DSJournalObjectXMLMapping;
    }
    return self;
}


#pragma mark - Special DSFileReporter & Mapping

- (DSFileReporter*)createSpecialFileReporter{
    
    DSFileReporter *specialFileReporter = [DSFileReporter fileReporterWithMappingType:mapType];
    return specialFileReporter;
}

- (void)setMappingType:(DSJournalObjectMapping)mappingType{
    
    mapType = mappingType;
}


#pragma mark - DSEmailReporterProtocol (SENDING Email)

/**
    @abstract Установить Email-назначения
    @discussion
    Устанавливает имейл, на которыйбудет репортер  отправлять репорт. На самом деле так как то не автоматический отправитель - устанавливает это значение в Recepients MFMailComposeViewController
 
    @note Проверяет валидность переданного имейла
 
    @param destinationEmail      Имейл назначения (куда отправлять репорт)
 */
- (void)addDestinationEmail:(NSString*)destinationEmail{
    
    BOOL isValidEmail = [destinationEmail isValidEmail];
    NSAssert(isValidEmail, @"Destination Email is not valid in DSEmailReporter");
    
    destinationAddress = [destinationEmail copy];
}

/**
    @abstract Метод отправки имейла с прикрепленным файлом
    @discussion
    Является враппером над методом отсылки для множественных прикрепленных файлов.
 
    @see 
    sendEmailWithFileArray:
 
    @param emailData       Данные файла для отправки
    @param fileName       Как именовать файл с данными
 */
- (void)sendEmailWithData:(NSData*)emailData withFilename:(NSString*)fileName{
    
    NSAssert(emailData, @"FILE DATA Must be not nil");
    NSAssert(fileName, @"FILE NAME Must be not nil");
    
    [self sendEmailWithFileArray:@{fileName : emailData}];
}

/**
    @abstract Метод отправки имейла с множественными прикрепленными файлами
    @discussion
    Является основным методом репортера, который содержит всю логику отправки  email-письма. Использует стандартный MFMailComposeViewController.
 
    Имеет следующую последовательность выполнения : 
    <ol type="1">
        <li> Проверяет на возможность отсылки письма (настроен ли почтовый клиент, поддерживает ли устройство) </li>
        <li> Формирует и параметризует контроллер (передает destination Email, bodyMessage и пр. ) </li>
        <li> Прикреплят к письму все файлы (поддерживает вроде до 50 или 100 прикрепленных файлов в 1м письме) </li>
        <li> Находит наиболее подходящий view controller для модального отображения, и презентует MFMailComposeViewController </li>
    </ol>
 
    @note Важно, чтобы у пользователя был настроен почтовый клиент по-умолчанию
 
    @warning Позволяет отправлять только  некоторые текстовые файлы (т.к. имеет пока фиксированный MimeType == public.text)
 
    @param filesDictionary       Словарь файлов (имя файла -> данные файла)
 */
- (void)sendEmailWithFileArray:(NSDictionary <NSString*, NSData*> *)filesDictionary{
    
    BOOL canEmailing = [MFMailComposeViewController canSendMail];
    if(! canEmailing){
        NSLog(@"CAN NOT USE EMAIL : Your device doesn't support the composer sheet");
        return;
    }
    
    NSAssert(filesDictionary && filesDictionary.count > 0, @"FILES DICTIONARY Must be not nil");
    
    MFMailComposeViewController *mailController = [MFMailComposeViewController new];
    mailController.mailComposeDelegate = self;
    
    NSString *emailHtmlBodyText = [NSString stringWithFormat:@"ATTACHED %lu REPORT FILE", (unsigned long)filesDictionary.count];
    [mailController setSubject:@"DeepStorm Reporter"];
    [mailController setMessageBody:emailHtmlBodyText isHTML:NO];
    
    if(destinationAddress){
        [mailController setToRecipients:@[destinationAddress]];
    }
    
    // Прикрепляет все файлы к имейлу
    for (NSString *filenameKey in [filesDictionary allKeys]) {
        
        NSData *fileData = filesDictionary[filenameKey];
        [mailController addAttachmentData:fileData mimeType:@"public.text" fileName:filenameKey];
    }
    
    // Чтобы на корректном контроллере модальным представлением MFMailComposeViewController
    id<UIApplicationDelegate> appDelegate = (id<UIApplicationDelegate>)[UIApplication sharedApplication].delegate;
    UIViewController *currentVisibleController = [appDelegate.window visibleViewController];
    
    [currentVisibleController presentViewController:mailController animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

/// Метод делегата MFMailComposeViewControllerDelegate, получает результат отправки
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error{
    
    switch (result){
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - DSSimpleReporterProtocol

/**
    @abstract Метод отправки репорта журнала
    @discussion
    Собирает XML-информацию о журнале. Использует вспомогательный файловый репортер, который собирает XML-данные, сохраняет их в файл. После этого получает NSData и название файла, и выполняет отправку их по имейлу.
 
    @param reportingJournal      Журнал, который будет отправляться по имейлу
 */
- (void)sendReportJournal:(DSJournal *)reportingJournal{
    
    helpfulFileReporter = [self createSpecialFileReporter];
    [helpfulFileReporter sendReportJournal:reportingJournal];
    
    [self sendEmailWithFileArray:helpfulFileReporter.fileDataArray];
    [helpfulFileReporter removeDataFiles];
    helpfulFileReporter = nil;
}

/**
    @abstract Метод отправки репорта сервиса
    @discussion
    Собирает XML-информацию о сервисе. Использует вспомогательный файловый репортер, который собирает XML-данные, сохраняет их в файл. После этого получает NSData и название файла, и выполняет отправку их по имейлу.
 
    @param reportingService      Сервис, который будет отправляться по имейлу
 */
- (void)sendReportService:(DSBaseLoggedService *)reportingService{
    
    helpfulFileReporter = [self createSpecialFileReporter];
    [helpfulFileReporter sendReportService:reportingService];
    
    [self sendEmailWithFileArray:helpfulFileReporter.fileDataArray];
    [helpfulFileReporter removeDataFiles];
    helpfulFileReporter = nil;
}

#pragma mark - DSComplexReporterProtocol

/**
    @abstract Один из методов формирования комплексного  репорта
    @discussion
    Добавить данные журнала к комплексному репорту. Выполняет отложенную инициаризацию internalFileReporter. Сохраняет часть комплексного репорта в файл (как буфер)
 
    @param reportingJournal      Журнал, данные которого следует прикрепить к репорту
 */
- (void)addPartReportJournal:(DSJournal*)reportingJournal{
    
    if(! internalFileReporter){
        internalFileReporter = [self createSpecialFileReporter];
    }
    [internalFileReporter sendReportJournal:reportingJournal];
}

/**
    @abstract Один из методов формирования комплексного  репорта
    @discussion
    Добавить данные сервиса к комплексному репорту. Выполняет отложенную инициаризацию internalFileReporter. Сохраняет часть комплексного репорта в файл (как буфер)
 
    @param reportingService      Сервис, данные которого следует прикрепить к репорту
 */
- (void)addPartReportService:(DSBaseLoggedService*)reportingService{
    
    if(! internalFileReporter){
        internalFileReporter = [self createSpecialFileReporter];
    }
    [internalFileReporter sendReportService:reportingService];
}

/**
    @abstract  Метод отправки комплексного репорта
    @discussion
    Составляет из  всех частей комплексного репорта письмо, отправляет его, и удаляет буферные  файлы.
 */
- (void)performAllReports{
    
    [self sendEmailWithFileArray:internalFileReporter.fileDataArray];
    [internalFileReporter removeDataFiles];
    internalFileReporter = nil;
}


@end
