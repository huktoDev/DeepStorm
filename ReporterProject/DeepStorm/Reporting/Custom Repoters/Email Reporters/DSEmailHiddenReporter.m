////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSEmailHiddenReporter.m
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 01.03.16.
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

#define DS_NEED_LOG_CREDENTIALS 0

#import "DSEmailHiddenReporter.h"

#import "DSJournalXMLMapper.h"
#import "DSJournal.h"
#import "DSBaseLoggedService.h"
#import "DSFileReporter.h"
#import "NSString+DSEmailValidation.h"

#import "BBAES.h"

/// Helper-метод, переводящий строку с HEX-данными в Hex-data (NSData)
NSData *dataByIntepretingHexString(NSString *hexString) {
    char const *chars = hexString.UTF8String;
    NSUInteger charCount = strlen(chars);
    if (charCount % 2 != 0) {
        return nil;
    }
    NSUInteger byteCount = charCount / 2;
    uint8_t *bytes = malloc(byteCount);
    for (int i = 0; i < byteCount; ++i) {
        unsigned int value;
        sscanf(chars + i * 2, "%2x", &value);
        bytes[i] = value;
    }
    return [NSData dataWithBytesNoCopy:bytes length:byteCount freeWhenDone:YES];
}

@implementation DSEmailHiddenReporter{
    
    NSString *cryptIVString;
    NSString *cryptKeyString;
    
    void (^smtpBlock)(MCOSMTPSession*);
    
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


#pragma mark - Config DSEmailHiddenReporter

/**
    @abstract Установка параметров для дешифровки криптохранилища с SMTP-реквизитами
    @discussion
    Для дешифровки криптохранилиа (вместо обычного пароля) - требуется немного необычные параметры. Это IV - Initialization Vector (с помощью него задается стартовый вектор алгоритма шифрования). И keyString - ключ (строка, конвертируемая потом в HEX-вид (шестнадцатиричный)) - ключ для дешифровки
 
    Устанавливает реквизиты, которые будут использоваться в дальнейшем для дешифровки данных из криптохранилища
 
    @param IVString      NSString , Initialization Vector (16-ти байтный)
    @param keyString       NSString (в hex-виде), строка, которая будет преобразована в 32-х байтный ключ
 */
- (void)setDecryptorWithIV:(NSString*)IVString withKey:(NSString*)keyString{
    
    NSAssert(IVString, @"IVString must be not nil");
    NSAssert(keyString, @"keyString must be not nil");
    
    cryptIVString = [IVString copy];
    cryptKeyString = [keyString copy];
}

/**
    @abstract Метод, позволяющий кастомно сконфигурировать SMTP-сессию
    @discussion
    Дает возможность клиенту репортера выполнить конфигурирование SMTP-сессии вручную. Для этого пользователь может определить специальный конфигурационный блок!
 
    @note Конфигурационный блок выполняется после установки реквизитов из криптохранилища
    @warning Крайне небезопасно определять userName & password SMTP-сессии здесь вручную
 
    @see
    MCOSMTPSession \n
    <a href="MailCore Start Page"> http://libmailcore.com </a>
 
    @param Конфигурационный блок для SMTP-сессии
 */
- (void)addConfigSMTPSession:(void (^)(MCOSMTPSession*))configSessionBlock{
    
    NSAssert(configSessionBlock, @"configSessionBlock must be not nil");
    smtpBlock = [configSessionBlock copy];
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
    Является основным методом репортера, который содержит всю логику отправки  email-письма. Использует фреймворк MailCore для работы с IMAP/POP3/SMTP протоколами.
 
    Для работы требует установить  SMTP-сессию (нужен исходящий имейл, его пароль и некоторые конфиг-данные)
 
    @note Самое главное  для использование этого метода - это то, что он извлекает некоторые реквизиты SMTP-сессии из криптохранилища.
 
    <h4> Как создать криптоконтейнер реквизитов, и сделать так, чтобы его увидел этот репортер !!! </h4>
    <ol type = "1">
        <li> Создайте или модифицируйте имеющийся DS_ECreds.plist файл. Добавьте следующие поля :
            <ol type="a">
                <li> поле DS_EMAIL (напр. vash_zloy13rock@mail.ru) </li>
                <li> поле DS_PASS (напр. qwerty1234) </li>
            </ol>
        </li>
        <li> Добавьте скрипт на shell script phase в Xcode (исполнится непосредственно в конце этапа компиляции и зашифрует ваш .plist файл в .enc файл, и удалит исходный в TARGET_BUILD_DIR) </li>
        <li> SHELL SCRIPT : 
            @code 
            echo "run build phase DeepStorm shell Script"
 
            srcPath="$PROJECT_DIR/$PROJECT_NAME/DS_ECreds.plist";
            destEncFilePath="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/DS_ECreds.enc"
 
            destSrcFileDirPath="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/"
            srcFileName="DS_ECreds.plist"
 
            echo "srcPath: $srcPath"
            echo "destPath: $destEncFilePath"
 
            openssl aes-256-cbc -e -K __ENCRYPT_KEY__ -iv __ENCRYPT_IV__ -in $srcPath -out $destEncFilePath
            cd
            cd $destSrcFileDirPath
            rm $srcFileName
            @endcode
 
        </li>
        <li> Примеры ENCRYPT_PARAMS :
            <ul>
                <li> <b> __ENCRYPT_KEY__ </b>  - 32byte Hex-data (например, D8578EDF8458CE06FBC5BB76A58C5CA4D8578EDF8458CE06FBC5BB76A58C5CA4) </li>
                <li>  <b> __ENCRYPT_IV__ </b> - 16byte Hex-data (например, 1234567890abcdef1234567890abcdef) </li>
            </ul>
        </li>
        <li> Ключ и вектор лучше всего сгенерить с помощью bash-терминала предварительно!
 
                Генерация ENCRYPT_PARAMS :
            <ol type="a">
                <li> generate key : openssl rand -hex 32 </li>
                <li> generate  IV : openssl rand -hex 16 </li>
            </ol> </li>
    </ol>
 
    <h4> Последовательность выполнения : </h4>
    <ol type="1">
        <li> Используя опен-сорс либу BBAES выполняет дешифровку файла DS_ECreds.enc </li>
        <li> Извлекает из дешифрованных данных реквизиты SMTP-сессии, и проверяет их на валидность </li>
        <li> Создать и сконфигурировать SMTP-сессию </li>
        <li> Создать объект SMTP-операции (письмо), прикрепить файлы и прочие данные </li>
        <li> Выполнить отправку имейла </li>
    </ol>
 
    @param filesDictionary       Словарь файлов (имя файла -> данные файла)
 */
- (void)sendEmailWithFileArray:(NSDictionary <NSString*, NSData*> *)filesDictionary{
    
    NSAssert(filesDictionary && filesDictionary.count > 0, @"FILES DICTIONARY Must be not nil");
    
    // Проверить, корректно ли удален plist файл в таргет-бандле, из которого генерился зашифрованный файл с
    NSString *baseCredsPath = [[NSBundle mainBundle] pathForResource:@"DS_ECreds" ofType:@"plist"];
    BOOL unsafeCredsDeleted = (BOOL)(baseCredsPath == nil);
    NSAssert(unsafeCredsDeleted, @"Error Shell Script : File with Unsafe credntials isn't deleted");
    
    // Извлечь зашифрованные данные
    NSString *encryptedCredsPath = [[NSBundle mainBundle] pathForResource:@"DS_ECreds" ofType:@"enc"];
    NSData *encryptedCredsData =[[NSData alloc] initWithContentsOfFile:encryptedCredsPath];
    
    // Получить Initialization Vector и Encryption Key
    NSAssert(cryptIVString && cryptKeyString, @"CRYPT IV & CRYPT KEY not installed");
    NSData *cryptIV = dataByIntepretingHexString(cryptIVString);
    NSData *cryptKey = dataByIntepretingHexString(cryptKeyString);
    
    // Попытаться расшифровать данные
    NSData *decryptedCredsData = [BBAES decryptedDataFromData:encryptedCredsData IV:cryptIV key:cryptKey];
    NSDictionary *credentialsDict = [NSPropertyListSerialization propertyListWithData:decryptedCredsData options:NSPropertyListImmutable format:nil error:nil];
    
    // Проверить, удалось ли расшифровать данные
    if(! credentialsDict || [credentialsDict isEqual:[NSNull null]]){
        @throw [NSException exceptionWithName:@"CryptReporerException" reason:@"Decryption cryptoContainer failed" userInfo:nil];
    }
    if(credentialsDict[@"DS_EMAIL"] == nil){
        @throw [NSException exceptionWithName:@"CredsReporerException" reason:@"Email not defined in DS_ECreds. Must be have key DS_EMAIL" userInfo:nil];
    }
    if(credentialsDict[@"DS_PASS"] == nil){
        @throw [NSException exceptionWithName:@"CredsReporerException" reason:@"Pass not defined in DS_ECreds. Must be have key DS_PASS" userInfo:nil];
    }
    
    // Получить реквизиты
    NSString *emailUsername = credentialsDict[@"DS_EMAIL"];
    NSString *emailPassword = credentialsDict[@"DS_PASS"];
    
    BOOL isValidCredsEmail = [emailUsername isValidEmail];
    NSAssert(isValidCredsEmail, @"Decrypted SMTP-Session Email is not valid email");
    
#if DS_NEED_LOG_CREDENTIALS == 1
    NSLog(@"DEFINED CREDENTIALS : %@", credentialsDict);
#endif
    
    // Сконфигурировать SMTP-сессию
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.username = emailUsername;
    smtpSession.password = emailPassword;
    
    NSAssert(smtpBlock, @"SMTP Session do not configured! Use addConfigSMTPSession:");
    smtpBlock(smtpSession);
    
    NSAssert(destinationAddress, @"Destination Address must be not nil !!!");
    
    // Сконфигурировать сам отправляемый Email
    NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *emailSubject = @"DeepStorm Reporter";
    NSString *emailHtmlBodyText = [NSString stringWithFormat:@"ATTACHED %lu REPORT FILE", (unsigned long)filesDictionary.count];
    
    MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];
    MCOAddress *from = [MCOAddress addressWithDisplayName:appBundleID
                                                  mailbox:emailUsername];
    MCOAddress *to = [MCOAddress addressWithDisplayName:nil
                                                mailbox:destinationAddress];
    [[builder header] setFrom:from];
    [[builder header] setTo:@[to]];
    [[builder header] setSubject:emailSubject];
    [builder setHTMLBody:emailHtmlBodyText];
    
    for (NSString *filenameKey in [filesDictionary allKeys]) {
        
        NSData *fileData = filesDictionary[filenameKey];
        MCOAttachment *fileAttachment = [MCOAttachment attachmentWithData:fileData filename:filenameKey];
        [builder addAttachment:fileAttachment];
    }
    
    // Сформировать конечное письмо, и отправить его на почтовый сервер
    NSData *rfc822Data = [builder data];
    
    __block NSString *currentDestEmail = [destinationAddress copy];
    MCOSMTPSendOperation *sendOperation =
    [smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        if(error) {
            NSLog(@"Error sending email: %@", error);
        } else {
            NSLog(@"Successfully sent email to %@ !", currentDestEmail);
        }
    }];
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
    Добавить данные сервиса к комплексному репорту. Выполняет  отложенную инициаризацию internalFileReporter. Сохраняет часть комплексного репорта в файл (как буфер)
 
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
    internalFileReporter = nil;
}

@end
