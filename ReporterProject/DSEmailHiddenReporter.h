////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSEmailHiddenReporter.h
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

#import <Foundation/Foundation.h>
#import "DSReporting.h"
#import "DSEmailReporterProtocol.h"
#import "DSJournalMappingProtocol.h"

#import <MailCore/MailCore.h>

/**
    <hr>
    @class DSEmailHiddenReporter
    @author HuktoDev
    @updated 20.03.2016
    @abstract Класс-репортер, выполняющий скрытую отправку репортов на Email
    @discussion
    Выполняет скрытую отправку письма в бэкграунде, используя возможности MailCore - мощного фреймворка для работы с почтовыми протоколами. Для отправки письма использует  SMTP-сессию
    Определяет реализацию 2х протоколов : DSReporterProtocol и DSEmailReporterProtocol
    <hr>
 
    @warning Берет реквизиты SMTP-сессии из криптохранилища DS_ECreds.enc, для этого надо создать криптохранилище :
 
    <h4> Как создать криптоконтейнер реквизитов, и сделать так, чтобы его увидел этот репортер !!! </h4>
    <ol type = "1">
        <li> Создайте или модифицируйте имеющийся DS_ECreds.plist файл. Добавьте следующие поля :
            <ol type="a">
                <li> поле DS_EMAIL (напр. vash_zloy13rock@mail.ru) </li>
                <li> поле DS_PASS (напр. qwerty1234) </li>
            </ol>
        </li>
        <li> Добавьте скрипт на shell script phase в Xcode (исполнится непосредственно в конце этапа компиляции и зашифрует ваш .plist файл в .enc файл, и удалит исходный в TARGET_BUILD_DIR)
        </li>
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
            </ol>
        </li>
    </ol>
 
    <hr>
    @note ОТПРАВЛЯЕТ EMAIL без ведома пользователя! Можно даже собирать таким образом статистику с работающих в текущий момент приложений! Только Apple может режектить такие приложения, так что этот механизм значительно безопаснее использовать именно при отладке.
 */
@interface DSEmailHiddenReporter : NSObject <DSReporterProtocol, DSEmailReporterProtocol>


#pragma mark - Change Mapping
// Изменение типа маппинга (XML/JSON)

- (void)setMappingType:(DSJournalObjectMapping)mappingType;


#pragma mark - Config DSEmailHiddenReporter
// Конфигурирование репортера

- (void)setDecryptorWithIV:(NSString*)IVString withKey:(NSString*)keyString;
- (void)addConfigSMTPSession:(void (^)(MCOSMTPSession*))configSessionBlock;



#pragma mark - DSEmailReporterProtocol
// Методы для отправки имейла

- (void)addDestinationEmail:(NSString*)destinationEmail;

- (void)sendEmailWithData:(NSData*)emailData withFilename:(NSString*)fileName;
- (void)sendEmailWithFileArray:(NSDictionary <NSString*, NSData*> *)filesDictionary;



#pragma mark -  DSSimpleReporterProtocol
// Методы для отправки простого репорта

- (void)sendReportJournal:(DSJournal *)reportingJournal;
- (void)sendReportService:(DSBaseLoggedService *)reportingService;



#pragma mark - DSComplexReporterProtocol
// Методы для отправки составного репорта

- (void)addPartReportJournal:(DSJournal*)reportingJournal;
- (void)addPartReportService:(DSBaseLoggedService*)reportingService;
- (void)performAllReports;


@end
