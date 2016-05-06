//
//  LXNNotifier.h
//  LXNNotifier
//
//  Created by Leszek Kaczor on 12/03/15.
//  Copyright (c) 2015 Leszek Kaczor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    LXNNotifierPositionTop,
    LXNNotifierPositionMid,
    LXNNotifierPositionBottom,
    LXNNotifierPositionCount, //leave it at the end of enum
} LXNNotifierPosition;

typedef void (^LXNNotifierCompletedAnimationBlock)();
typedef void (^LXNNotifierDismissBlock)();
typedef void (^LXNNotifierAnimationBlock)(UIView * view, LXNNotifierCompletedAnimationBlock completionBlock);


@interface LXNNotifier : NSObject

/**
 *  Default 2 seconds
 */
@property (nonatomic, assign) CGFloat notificationDuration;

+ (instancetype)sharedInstance;
- (UIView *)showNotificationWithView:(UIView *)view;
- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position;
- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position shouldDismissOnTap:(BOOL)shouldDismiss dismissOnTapBlock:(LXNNotifierDismissBlock)dismissBlock;
- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position notificationDuration:(CGFloat)duration shouldDismissOnTap:(BOOL)shouldDismiss dismissOnTapBlock:(LXNNotifierDismissBlock)dismissBlock;
- (void)hideNotificationWithView:(UIView *)view;

- (UIView *)currentNotificationViewForPosition:(LXNNotifierPosition)position;

- (void)setShowAnimation:(LXNNotifierAnimationBlock)animation forPosition:(LXNNotifierPosition)position;
- (void)setHideAnimation:(LXNNotifierAnimationBlock)animation forPosition:(LXNNotifierPosition)position;

/**
 *  @return if view is dismissing and cannot increase duration returns NO, otherwise returns YES
 */
- (BOOL)increaseNotificationDurationBy:(CGFloat)value forView:(UIView *)view;

/**
 *  If view is presented set notification duration from current time. If not presented just set notification duration.
 *
 *  @param value a notification duration
 *  @param view  a view to display
 *
 *  @return if view is dismissing and cannot increase duration returns NO, otherwise returns YES
 */
- (BOOL)setNotificationDurationFromNow:(CGFloat)value forView:(UIView *)view;

/**
 *  Returns view on which notification will be displayed. 
 *  By default it returns application's key window.
 *  You can override if if you want to change place notifications are presenting.
 *
 *  @return the view for displaying notification
 */
- (UIView *)viewForDisplayingNotification;

@end
