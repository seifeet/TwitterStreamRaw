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
@property (nonatomic, strong) NSString *term;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSOperationQueue *queue;

@property BOOL shouldRestart;

@end

@implementation SFTwitterStream

- (id)init
{
    self = [super init];
    if (self) {
        
        _queue = [[NSOperationQueue alloc] init];
        _shouldRestart = NO;
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
    self.term = term;

    [self startQueue];
}

- (void)startQueue
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:self.term
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
    [self stopQueue];
}

- (void)stopQueue
{
    [self.queue setSuspended:YES];
    [self.queue cancelAllOperations];
    [self.queue addOperationWithBlock:^{
        [self.connection cancel];
    }];
    [self.queue setSuspended:NO];
}

#pragma mark - private helper methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    for (NSString *tweet in [response componentsSeparatedByString:@"\r\n"]) {

        if ([tweet length]) {
            [self parseTweet:tweet];
        }
    }
}

- (void)parseTweet:(NSString *)tweet
{
    NSData *data = [tweet dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

    if (json && self.dataReceivedBlock){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataReceivedBlock(json);
        });
    }

    if (!json) {
        NSLog(@" ------------ Failed to parse a tweet");
        NSLog(@"%@", tweet);
        NSLog(@" ------------");
    }
}

@end
