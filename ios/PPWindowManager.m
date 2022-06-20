//
//  PPWindowManager.m
//  react-native-photo-picker
//
//  Created by 高昇 on 2021/5/30.
//

#import "PPWindowManager.h"

@implementation PPWindowManager

static PPWindowManager* _instance = nil;

+ (instancetype)shareManager
{
  static dispatch_once_t onceToken ;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init] ;
  }) ;
  return _instance ;
}

- (UIWindow *)getMainWindow
{
  id appDelegate = [UIApplication sharedApplication].delegate;
  if (appDelegate && [appDelegate respondsToSelector:@selector(window)]) {
    return [appDelegate window];
  }
  NSArray *windows = [UIApplication sharedApplication].windows;
  if ([windows count] == 1) {
    return [windows firstObject];
  } else {
    for (UIWindow *window in windows) {
      if (window.windowLevel == UIWindowLevelNormal) {
        return window;
      }
    }
  }
  return nil;
}


- (UIViewController *)jsd_findVisibleViewController
{
  UIViewController* currentViewController = [self getMainWindow].rootViewController;
  BOOL runLoopFind = YES;
  while (runLoopFind) {
    if (currentViewController.presentedViewController) {
      currentViewController = currentViewController.presentedViewController;
    } else {
      if ([currentViewController isKindOfClass:[UINavigationController class]]) {
        currentViewController = ((UINavigationController *)currentViewController).visibleViewController;
      } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
        currentViewController = ((UITabBarController* )currentViewController).selectedViewController;
      } else {
        break;
      }
    }
  }
  return currentViewController;
}

@end
