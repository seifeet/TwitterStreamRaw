//
//  SFTwitterAccountManager.h
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SFTwitterAccountManager : NSObject
{

}

+ (SFTwitterAccountManager *)sharedManager;

- (void)selectAccountWithCompletionBlock:(ObjectCompletionBlock)completionBlock;

@end
