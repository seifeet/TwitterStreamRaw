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

#import "Reachability.h"

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
@property (nonatomic, strong) Reachability *internetReachable;

@property BOOL shouldRestart;

@end

@implementation SFTwitterStream

- (id)init
{
    self = [super init];
    if (self) {
        
        _queue = [[NSOperationQueue alloc] init];
        _internetReachable = nil;
        _shouldRestart = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopReachability];
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

        [self startReachability];
    }
    return self;
}

- (void)startWithTerm:(NSString *)term
{
    self.shouldRestart = YES;
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
    self.shouldRestart = NO;

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

- (void)startReachability
{
    if (!self.internetReachable) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];

        self.internetReachable = [Reachability reachabilityForInternetConnection];
        [self.internetReachable startNotifier];
    }
}

- (void)stopReachability
{
    if (self.internetReachable) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [self.internetReachable stopNotifier];
        self.internetReachable = nil;
    }
}

-(void) checkNetworkStatus:(NSNotification *)notice
{
    NetworkStatus internetStatus = [self.internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            if (self.shouldRestart) {
                [self stopQueue];
            }
            break;
        }
        case ReachableViaWiFi:
        case ReachableViaWWAN:
        {
            if (self.shouldRestart) {
                [self startQueue];
            }
            break;
        }
    }
}

@end
