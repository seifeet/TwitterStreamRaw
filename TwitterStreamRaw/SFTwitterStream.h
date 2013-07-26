//
//  SFTwitterStream.h
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

@interface SFTwitterStream : NSObject
{

}


- (id)initWithAccount:(ACAccount *)account
           controller:(NSString *)controller
               action:(NSString *)action
 andDataReceivedBlock:(ObjectCompletionBlock)dataReceivedBlock;

- (void)startWithTerm:(NSString *)term;
- (void)stop;

@end
