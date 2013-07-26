//
//  SFAlertHelper.h
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFAlertHelper : NSObject
{

}

+ (SFAlertHelper *)sharedHelper;

- (void)noTwitterAccounts;

@end
