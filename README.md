## LXNNotifier

This is the repository for LXNNotifier.

## Installation

Add following line to your Podfile

```
pod 'LXNNotifier', :git => "https://bitbucket.org/ducker/lxnnotifier.git"
```

If no cocoapods installed go to http://cocoapods.org for further informations.

## Usage
```objective-c
[[LXNNotifier sharedInstance] showNotificationWithView:[[UIView alloc] init] position:LXNNotifierPositionTop shouldDismissOnTap:YES dismissOnTapBlock:^{
    // dissmiss action
}];
```