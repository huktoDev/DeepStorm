////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      DSJournalMacroses.h
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

#ifndef DSJournalMacroses_h
#define DSJournalMacroses_h


// OUTPUT STREAM DEFINED MACRO ->

#define DSJOURNAL_LOG_STREAMING 0

#if DSJOURNAL_LOG_STREAMING == 1
    #define DSLOGGER_STREAM_MACRO     NSLog
#else
    #undef DSLOGGER_STREAM_MACRO
#endif


//MARK: писать логи только через эту строку, потому-что с ней можно сделать undef

#define DSJOURNAL_LOGGING_ON 1

#define DSJOURNAL_LOG (DEBUG == 1 && DSJOURNAL_LOGGING_ON == 1)

typedef void (^DSSimpleBlockCode)(void);
static inline void journal_code(DSSimpleBlockCode blockCode){
#if DSJOURNAL_LOG == 1
    blockCode();
#endif
}

#if DSJOURNAL_LOG

    #define DSJOURNALLING(a); journal_code(a);
    #define DSLOG_SERVICE(service, logString); [service log:logString];
    #define DSLOG_SERVICE_INFO(service, logString, info); [service log:logString withInfo:info];
    #define DSJOURNALLING_LOG(...); DSJOURNALLING((^{ \
        NSString *logString = [NSString stringWithFormat:__VA_ARGS__]; \
        DSLOG_SERVICE(self, logString); \
    }));
#else
    #define DSJOURNALLING(a);
    #define DSLOG_SERVICE(service, logString);
    #define DSLOG_SERVICE_INFO(service, logString, info);
    #define DSJOURNALLING_LOG(...);
#endif

#endif
