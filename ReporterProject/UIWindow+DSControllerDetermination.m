////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *      UIWindow+DSControllerDetermination.m
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

#import "UIWindow+DSControllerDetermination.h"

@implementation UIWindow (DSControllerDetermination)

/**
    @abstract Определяет текущий видимый контроллер для окна
    @discussion
    Проходит по всей иерархии контроллеров для UIWindow, начинает с rootViewController. Видимый контроллер часто бывает нужен, когда требуется отобразить какой-то контроллер их внешнего модуля, никак не связанного с определенным контроллером вью.
 
    @return Найденный текущий отображаемый контроллер
 */
- (UIViewController *)visibleViewController {
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

/**
    @abstract Метод обхода  иерархии контроллера
    @discussion
    Выполняет задачу обхода всей иерархии контроллера в поиске текущего видимого контроллера (выполняется рекурсивно).
 
    @param viewController     объект UIViewController, для внутренней иерархии которого нужно выполнять поиск
    @return  Следующая найденная ветвь, приближающая нас к видимому контроллеру (или сам видимый контроллер)
*/
+ (UIViewController *)getVisibleViewControllerFrom:(UIViewController *) viewController {
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) viewController) visibleViewController]];
        
    } else if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) viewController) selectedViewController]];
    } else {
        if (viewController.presentedViewController) {
            return [UIWindow getVisibleViewControllerFrom:viewController.presentedViewController];
        }else if(viewController.presentingViewController){
            return [UIWindow getVisibleViewControllerFrom:viewController.presentingViewController];
        }else {
            return viewController;
        }
    }
}

@end
