////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      UIWindow+DSControllerDetermination.h
 *      DeepStorm Framework
 *
 *      Created by Alexandr Babenko on 19.03.16.
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

#import <UIKit/UIKit.h>

/**
    @category UIWindow (DSControllerDetermination)
    @abstract Категория, выполняющего для окна поиск отображаемого UIViewController (поиск рекурсивный)
 */
@interface UIWindow (DSControllerDetermination)

- (UIViewController *)visibleViewController;
+ (UIViewController *)getVisibleViewControllerFrom:(UIViewController *)viewController;

@end
