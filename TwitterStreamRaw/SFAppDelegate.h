//
//  SFAppDelegate.h
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SFTableViewController;
@class Reachability;

@interface SFAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SFTableViewController *viewController;

@property (nonatomic, strong) Reachability *internetReachable;

@end
