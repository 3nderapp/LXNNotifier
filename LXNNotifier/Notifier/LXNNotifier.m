//
//  LXNNotifier.m
//  LXNNotifier
//
//  Created by Leszek Kaczor on 12/03/15.
//  Copyright (c) 2015 Leszek Kaczor. All rights reserved.
//
@import UIKit;
#import <objc/runtime.h>
#import "LXNNotifier.h"

typedef void (^LXNNotifierDifferenceBlock)(CGFloat diff);

static void const * lxn_viewShowDate            = &lxn_viewShowDate;

static void const * lxn_animationSemaphoreKey   = &lxn_animationSemaphoreKey;
static void const * lxn_waitSemaphoreKey        = &lxn_waitSemaphoreKey;
static void const * lxn_completeSemaphoreKey    = &lxn_completeSemaphoreKey;

static void const * lxn_dismissBlockKey         = &lxn_dismissBlockKey;
static void const * lxn_animationDurationKey    = &lxn_animationDurationKey;

static void const * lxn_viewDismissedKey        = &lxn_viewDismissedKey;

static NSString * const lxn_customShowAnimationForPositionFormat = @"lxn_kCustomShowAnimationForPosition_%ld";
static NSString * const lxn_customHideAnimationForPositionFormat = @"lxn_kCustomHideAnimationForPosition_%ld";
static NSString * const lxn_currentNotificationForPositionFormat = @"lxn_kCurrentNotificationForPosition_%ld";

@interface LXNNotifier()

@property (nonatomic, strong, readonly) NSArray * operationQueueArray;

@property (nonatomic, strong) NSDictionary * customAnimationsDictionary;
@property (nonatomic, strong) NSMapTable * currentNotificationMap;

@end

@implementation LXNNotifier

#pragma mark - Private API -
#pragma mark - Initialization
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static LXNNotifier * instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _notificationDuration = 2.0f;
        _operationQueueArray = [self createOperationsForAllPositions];
        _currentNotificationMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
    }
    return self;
}

- (NSOperationQueue *)createOperationQueueForNotifier
{
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    return queue;
}

- (NSArray *)createOperationsForAllPositions
{
    NSMutableArray * mutableOperationQueueArray = [NSMutableArray arrayWithCapacity:LXNNotifierPositionCount - 1];
    for (int i=0; i<LXNNotifierPositionCount; i++)
        [mutableOperationQueueArray addObject:[self createOperationQueueForNotifier]];
    return [mutableOperationQueueArray copy];
}

- (UIView *)viewForDisplayingNotification
{
    UIWindow * mainWindow = [[UIApplication sharedApplication] keyWindow];
    return mainWindow;
}

#pragma mark - Associated objects
- (void)addAnimationSemaphoreToView:(UIView *)view
{
    dispatch_semaphore_t animationSemaphore = dispatch_semaphore_create(0);
    objc_setAssociatedObject(view, lxn_animationSemaphoreKey, animationSemaphore, OBJC_ASSOCIATION_RETAIN);
}

- (dispatch_semaphore_t)getAnimationSemaphoreFromView:(UIView *)view
{
    dispatch_semaphore_t sem = objc_getAssociatedObject(view, lxn_animationSemaphoreKey);
    return sem;
}

- (void)setShowDate:(NSDate *)date forView:(UIView *)view
{
    objc_setAssociatedObject(view, lxn_viewShowDate, date, OBJC_ASSOCIATION_RETAIN);
}

- (NSDate *)getShowDateForView:(UIView *)view
{
    NSDate * date = objc_getAssociatedObject(view, lxn_viewShowDate);
    return date;
}

- (void)addWaitSemaphoreToView:(UIView *)view
{
    dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);
    objc_setAssociatedObject(view, lxn_waitSemaphoreKey, waitSemaphore, OBJC_ASSOCIATION_RETAIN);
}

- (dispatch_semaphore_t)getWaitSemaphoreFromView:(UIView *)view
{
    dispatch_semaphore_t sem = objc_getAssociatedObject(view, lxn_waitSemaphoreKey);
    return sem;
}

- (void)addCompleteSemaphoreToView:(UIView *)view
{
    dispatch_semaphore_t completeSemaphore = dispatch_semaphore_create(0);
    objc_setAssociatedObject(view, lxn_completeSemaphoreKey, completeSemaphore, OBJC_ASSOCIATION_RETAIN);
}

- (dispatch_semaphore_t)getCompleteSemaphoreFromView:(UIView *)view
{
    dispatch_semaphore_t sem = objc_getAssociatedObject(view, lxn_completeSemaphoreKey);
    return sem;
}

- (void)addDismissBlock:(LXNNotifierDismissBlock)dissmissBlock ToView:(UIView *)view
{
    objc_setAssociatedObject(view, lxn_dismissBlockKey, dissmissBlock, OBJC_ASSOCIATION_COPY);
}

- (LXNNotifierDismissBlock)getDismissBlockFromView:(UIView *)view
{
    return objc_getAssociatedObject(view, lxn_dismissBlockKey);
}

- (void)addAnimationDuration:(CGFloat)duration forView:(UIView *)view
{
    CGFloat value = duration == MAXFLOAT || [self getAnimationDurationForView:view] == MAXFLOAT ? MAXFLOAT : [self getAnimationDurationForView:view] + duration;
    [self setAnimationDuration:value forView:view];
}

- (void)setAnimationDuration:(CGFloat)duration forView:(UIView *)view
{
    objc_setAssociatedObject(view, lxn_animationDurationKey, @(duration), OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)getAnimationDurationForView:(UIView *)view
{
    NSNumber * animationDuration = objc_getAssociatedObject(view, lxn_animationDurationKey);
    return (CGFloat)animationDuration.doubleValue;
}

- (void)setDismissed:(BOOL)dismissed view:(UIView *)view
{
    objc_setAssociatedObject(view, lxn_viewDismissedKey, @(dismissed), OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)isViewDismissed:(UIView *)view
{
    // if semaphore is null view is waiting for presentation
    dispatch_semaphore_t sem = [self getWaitSemaphoreFromView:view];
    if (sem)
    {
        NSNumber * animationDuration = objc_getAssociatedObject(view, lxn_viewDismissedKey);
        return animationDuration.boolValue;
    }
    return NO;
}

#pragma mark - Tap Recognizer
- (void)addHideGestureRecognizerToView:(UIView *)view
{
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [view addGestureRecognizer:recognizer];
}

- (void)tapAction:(UITapGestureRecognizer *)recognizer
{
    UIView * view = recognizer.view;
    [self hideNotificationWithView:view];
    LXNNotifierDismissBlock dismissBlock = [self getDismissBlockFromView:view];
    if (dismissBlock) dismissBlock();
}

#pragma mark - Configure and present notification
- (void)adjustView:(UIView *)view forPosition:(LXNNotifierPosition)position
{
    UIView * viewForNotification = [self viewForDisplayingNotification];
    CGRect frame = view.frame;
    switch (position) {
        case LXNNotifierPositionTop:
            frame.origin.y = 0;
            frame.size.width = viewForNotification.bounds.size.width;
            break;
        case LXNNotifierPositionMid:
            frame.origin.x = (viewForNotification.bounds.size.width - frame.size.width)/2;
            frame.origin.y = (viewForNotification.bounds.size.height - frame.size.height)/2;
            break;
        case LXNNotifierPositionBottom:
            frame.origin.y = viewForNotification.bounds.size.height - frame.size.height;
            frame.size.width = viewForNotification.bounds.size.width;
            break;
        default:
            break;
    }
    view.frame = frame;
}

- (void)prepareViewToShow:(UIView *)view position:(LXNNotifierPosition)position duration:(CGFloat)duration shouldDismissOnTap:(BOOL)shouldDismiss dismissBlock:(LXNNotifierDismissBlock)dismissBlock
{
    [self setDismissed:NO view:view];
    [self setCurrentNotificationView:view forPosition:position];
    [self adjustView:view forPosition:position];
    [self addAnimationSemaphoreToView:view];
    [self addWaitSemaphoreToView:view];
    [self setAnimationDuration:duration forView:view];
    [self addCompleteSemaphoreToView:view];
    [self addDismissBlock:dismissBlock ToView:view];
    if (shouldDismiss)
        [self addHideGestureRecognizerToView:view];
}

- (LXNNotifierAnimationBlock)showAnimationForPosition:(LXNNotifierPosition)position
{
    NSString * key = [NSString stringWithFormat:lxn_customShowAnimationForPositionFormat, (unsigned long)position];
    return self.customAnimationsDictionary[key];
}

- (LXNNotifierAnimationBlock)hideAnimationForPosition:(LXNNotifierPosition)position
{
    NSString * key = [NSString stringWithFormat:lxn_customHideAnimationForPositionFormat, (unsigned long)position];
    return self.customAnimationsDictionary[key];
}

- (void)setCurrentNotificationView:(UIView *)view forPosition:(LXNNotifierPosition)position
{
    NSString * key = [NSString stringWithFormat:lxn_currentNotificationForPositionFormat, (unsigned long)position];
    if (view == nil)
        [self.currentNotificationMap removeObjectForKey:key];
    else
        [self.currentNotificationMap setObject:view forKey:key];
}

- (void)showView:(UIView *)view withAnimationBlock:(LXNNotifierAnimationBlock)animationBlock
{
    __weak typeof(self) welf = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[self viewForDisplayingNotification] addSubview:view];
        LXNNotifierCompletedAnimationBlock block = ^{ dispatch_semaphore_signal([welf getAnimationSemaphoreFromView:view]); };
        if (animationBlock) animationBlock(view, block);
        else block();
    });
}

- (void)hideView:(UIView *)view withAnimationBlock:(LXNNotifierAnimationBlock)animationBlock
{
    __weak typeof(self) welf = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
        LXNNotifierCompletedAnimationBlock block = ^{
            dispatch_semaphore_signal([welf getCompleteSemaphoreFromView:view]);
            [view removeFromSuperview];
        };
        if (animationBlock) animationBlock(view, block);
        else block();
    });
}

- (LXNNotifierDifferenceBlock)prepareDismissWaitSemaphoreForView:(UIView *)view
{
    __weak typeof(self) welf = self;
    __weak __block LXNNotifierDifferenceBlock weakDiffrenceBlock;
    LXNNotifierDifferenceBlock diffrenceBlock;
    weakDiffrenceBlock = diffrenceBlock = ^(CGFloat diff){
        CGFloat currentAnimationDuration = [self getAnimationDurationForView:view];
        CGFloat difference = currentAnimationDuration - diff;
        if (fabs(difference) < 0.001f)
            [welf hideNotificationWithView:view];
        else if ([self getAnimationDurationForView:view] != MAXFLOAT)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fabs(difference) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (weakDiffrenceBlock)
                    weakDiffrenceBlock(currentAnimationDuration);
            });
    };
    return weakDiffrenceBlock;
}

- (NSOperation *)showOperationWithView:(UIView *)view position:(LXNNotifierPosition)position duration:(CGFloat)duration shouldDismissOnTap:(BOOL)shouldDismiss dismissBlock:(LXNNotifierDismissBlock)dismissBlock
{
    __weak typeof(self) welf = self;
    NSOperation * showOperation = [NSBlockOperation blockOperationWithBlock:^{
        [welf prepareViewToShow:view position:position duration:duration shouldDismissOnTap:shouldDismiss dismissBlock:dismissBlock];
        [welf showView:view withAnimationBlock:[self showAnimationForPosition:position]];
        dispatch_semaphore_wait([self getAnimationSemaphoreFromView:view], DISPATCH_TIME_FOREVER);
        [welf setShowDate:[NSDate date] forView:view];
        LXNNotifierDifferenceBlock weakDiffrenceBlock = [welf prepareDismissWaitSemaphoreForView:view];
        if (duration != MAXFLOAT)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (weakDiffrenceBlock)
                    weakDiffrenceBlock(duration);
            });
        dispatch_semaphore_wait([self getWaitSemaphoreFromView:view], DISPATCH_TIME_FOREVER);
        [welf setCurrentNotificationView:nil forPosition:position];
        [welf hideView:view withAnimationBlock:[self hideAnimationForPosition:position]];
        dispatch_semaphore_wait([self getCompleteSemaphoreFromView:view], DISPATCH_TIME_FOREVER);
    }];
    return showOperation;
}

#pragma mark - Public API -
#pragma mark - Configure
- (void)setShowAnimation:(LXNNotifierAnimationBlock)animation forPosition:(LXNNotifierPosition)position
{
    NSMutableDictionary * dictionary = [self.customAnimationsDictionary mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString * key = [NSString stringWithFormat:lxn_customShowAnimationForPositionFormat, (unsigned long)position];
    if (animation) dictionary[key] = animation;
    else [dictionary removeObjectForKey:key];
    self.customAnimationsDictionary = [dictionary copy];
}

- (void)setHideAnimation:(LXNNotifierAnimationBlock)animation forPosition:(LXNNotifierPosition)position
{
    NSMutableDictionary * dictionary = [self.customAnimationsDictionary mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString * key = [NSString stringWithFormat:lxn_customHideAnimationForPositionFormat, (unsigned long)position];
    if (animation) dictionary[key] = animation;
    else [dictionary removeObjectForKey:key];
    self.customAnimationsDictionary = [dictionary copy];
}

#pragma mark - Present and hide view
- (UIView *)showNotificationWithView:(UIView *)view
{
    return [self showNotificationWithView:view position:LXNNotifierPositionTop notificationDuration:self.notificationDuration shouldDismissOnTap:YES dismissOnTapBlock:nil];
}

- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position
{
    return [self showNotificationWithView:view position:position notificationDuration:self.notificationDuration shouldDismissOnTap:(position!=LXNNotifierPositionMid) dismissOnTapBlock:nil];
}

- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position shouldDismissOnTap:(BOOL)shouldDismiss dismissOnTapBlock:(LXNNotifierDismissBlock)dismissBlock
{
    return [self showNotificationWithView:view position:position notificationDuration:self.notificationDuration shouldDismissOnTap:shouldDismiss dismissOnTapBlock:dismissBlock];
}

- (UIView *)showNotificationWithView:(UIView *)view position:(LXNNotifierPosition)position notificationDuration:(CGFloat)duration shouldDismissOnTap:(BOOL)shouldDismiss dismissOnTapBlock:(LXNNotifierDismissBlock)dismissBlock
{
    NSParameterAssert(position != LXNNotifierPositionCount);
    if (view)
    {
        NSOperationQueue * operationQueue = self.operationQueueArray[position];
        [operationQueue addOperation:[self showOperationWithView:view position:position duration:duration shouldDismissOnTap:shouldDismiss dismissBlock:dismissBlock]];
    }
    return view;
}

- (UIView *)currentNotificationViewForPosition:(LXNNotifierPosition)position
{
    return [self.currentNotificationMap objectForKey:[NSString stringWithFormat:lxn_currentNotificationForPositionFormat, (unsigned long)position]];
}

- (BOOL)increaseNotificationDurationBy:(CGFloat)value forView:(UIView *)view
{
    @synchronized(view)
    {
        if ([self isViewDismissed:view])
            return NO;
        [self addAnimationDuration:value forView:view];
    }
    return YES;
}

- (BOOL)setNotificationDurationFromNow:(CGFloat)value forView:(UIView *)view
{
    @synchronized(view)
    {
        if ([self isViewDismissed:view])
            return NO;
        NSDate * showDate = [self getShowDateForView:view];
        if (showDate) {
            [self getAnimationDurationForView:view];
            CGFloat showTime = [[NSDate date] timeIntervalSinceDate:showDate];
            [self setAnimationDuration:showTime + value forView:view];
        } else {
            [self setAnimationDuration:value forView:view];
        }
    }
    return YES;
}

- (void)hideNotificationWithView:(UIView *)view
{
    @synchronized(view)
    {
        dispatch_semaphore_t sem = [self getWaitSemaphoreFromView:view];
        if (dispatch_semaphore_signal(sem))
            [self setDismissed:YES view:view];
    }
}

@end
