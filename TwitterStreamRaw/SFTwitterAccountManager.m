//
//  SFTwitterAccountManager.m
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import "SFTwitterAccountManager.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface SFTwitterAccountManager()

@end

@implementation SFTwitterAccountManager
{

}

+ (SFTwitterAccountManager *)sharedManager
{
    static SFTwitterAccountManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[SFTwitterAccountManager alloc] init];
    });

    return _sharedManager;
}


- (void)selectAccountWithCompletionBlock:(ObjectCompletionBlock)completionBlock
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountTypeTwitter = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    [accountStore requestAccessToAccountsWithType:accountTypeTwitter
                                          options:nil
                                       completion:^(BOOL granted, NSError *error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted && !error) {

                NSArray *accounts = [accountStore accountsWithAccountType:accountTypeTwitter];

                if (accounts && accounts.count) {
                    
                    completionBlock(accounts.lastObject);
                } else {

                    completionBlock(nil);
                }
            } else {
                
                completionBlock(nil);
            }
        });
    }];
}

@end
