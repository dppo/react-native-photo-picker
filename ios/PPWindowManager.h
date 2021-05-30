//
//  PPWindowManager.h
//  react-native-photo-picker
//
//  Created by 高昇 on 2021/5/30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPWindowManager : NSObject

+ (instancetype)shareManager;

- (UIWindow *)getMainWindow;

@end

NS_ASSUME_NONNULL_END
