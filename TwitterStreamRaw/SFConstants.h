//
//  SFConstants.h
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ObjectCompletionBlock)(id object);

FOUNDATION_EXPORT NSString *const kSFTwitterApiServerUrl;

#define SharedAppDelegate ((SFAppDelegate*)[[UIApplication sharedApplication] delegate])