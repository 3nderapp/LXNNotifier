//
//  ViewController.m
//  LXNNotifier
//
//  Created by Leszek Kaczor on 12/03/15.
//  Copyright (c) 2015 Leszek Kaczor. All rights reserved.
//

#import "ViewController.h"
#import "LXNNotifier.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [[LXNNotifier sharedInstance] setShowAnimation:^(UIView *view, LXNNotifierCompletedAnimationBlock completionBlock) {
        view.alpha = 0.0f;
        [UIView animateWithDuration:1.0f animations:^{
            view.alpha = 1.0f;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } forPosition:LXNNotifierPositionTop];
    [[LXNNotifier sharedInstance] setHideAnimation:^(UIView *view, LXNNotifierCompletedAnimationBlock completionBlock) {
        [UIView animateWithDuration:1.0f animations:^{
            view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            completionBlock();
        }];
    } forPosition:LXNNotifierPositionTop];
    UIView * view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView * view2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView * view3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view1.backgroundColor = [UIColor redColor];
    view2.backgroundColor = [UIColor greenColor];
    view3.backgroundColor = [UIColor blueColor];
    [[LXNNotifier sharedInstance] showNotificationWithView:nil];
    
    [[LXNNotifier sharedInstance] showNotificationWithView:view1 position:LXNNotifierPositionTop notificationDuration:MAXFLOAT shouldDismissOnTap:YES dismissOnTapBlock:nil];
    [[LXNNotifier sharedInstance] showNotificationWithView:view2];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView * view;
        if ((view = [[LXNNotifier sharedInstance] currentNotificationViewForPosition:LXNNotifierPositionTop]))
            [[LXNNotifier sharedInstance] increaseNotificationDurationBy:MAXFLOAT forView:view];
    });
    [[LXNNotifier sharedInstance] showNotificationWithView:view3];
    
    [[LXNNotifier sharedInstance] showNotificationWithView:[[UIView alloc] init] position:LXNNotifierPositionTop shouldDismissOnTap:YES dismissOnTapBlock:^{
        //dissmiss
    }];
}

- (IBAction)showButtonAction:(id)sender {
    
    UIView * view;
    if ((view = [[LXNNotifier sharedInstance] currentNotificationViewForPosition:LXNNotifierPositionTop]))
        NSLog(@"view exist: %@", view);
    UIView * view1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view1.backgroundColor = [UIColor colorWithRed:(arc4random()%255)/255.0f green:(arc4random()%255)/255.0f blue:(arc4random()%255)/255.0f alpha:1.0f];
    [[LXNNotifier sharedInstance] showNotificationWithView:view1];

}

- (IBAction)extendButtonAction:(id)sender {
    UIView * view;
    if ((view = [[LXNNotifier sharedInstance] currentNotificationViewForPosition:LXNNotifierPositionTop]))
        [[LXNNotifier sharedInstance] increaseNotificationDurationBy:MAXFLOAT forView:view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
