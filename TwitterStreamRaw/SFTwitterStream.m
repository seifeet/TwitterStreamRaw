//
//  SFTwitterStream.m
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import "SFTwitterStream.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface SFTwitterStream()
{

}

@property (readwrite, copy) ObjectCompletionBlock dataReceivedBlock;

@property (nonatomic, strong) ACAccount *account;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation SFTwitterStream

- (id)init
{
    self = [super init];
    if (self) {
        
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (id)initWithAccount:(ACAccount *)account
           controller:(NSString *)controller
               action:(NSString *)action
 andDataReceivedBlock:(ObjectCompletionBlock)dataReceivedBlock
{
    if (self = [self init]) {

        _account = account;
        _action = action;
        _dataReceivedBlock = dataReceivedBlock;

        _url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kSFTwitterApiServerUrl, controller]];
    }
    return self;
}

- (void)startWithTerm:(NSString *)term
{
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:term
                                                           forKey:self.action];
    
    SLRequest *request  = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                             requestMethod:SLRequestMethodPOST
                                                       URL:self.url
                                                parameters:parameters];
    
    [request setAccount:self.account];

    self.connection = [[NSURLConnection alloc] initWithRequest:request.preparedURLRequest
                                                      delegate:self
                                              startImmediately:NO];
    [self.connection setDelegateQueue:self.queue];
    [self.connection start];
}

- (void)stop
{
    [self.queue setSuspended:YES];
    [self.queue cancelAllOperations];
    [self.queue addOperationWithBlock:^{
        [self.connection cancel];
    }];
    [self.queue setSuspended:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"%@", [NSString stringWithUTF8String:[data bytes]]);
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

    if (json && self.dataReceivedBlock){

        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataReceivedBlock(json);
        });
    }
}

@end
