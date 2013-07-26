//
//  SFAlertHelper.m
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import "SFAlertHelper.h"

@implementation SFAlertHelper
{

}

+ (SFAlertHelper *)sharedHelper
{
    static SFAlertHelper *_sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedHelper = [[SFAlertHelper alloc] init];
    });

    return _sharedHelper;
}

- (void)noTwitterAccounts
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"No Twitter accounts found. Please consider adding an account.\nOpen Settings app on your device. Scroll to Twitter and sign in with a Twitter account."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
