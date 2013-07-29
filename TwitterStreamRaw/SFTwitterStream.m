//
//  SFTwitterStream.m
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import "SFTwitterStream.h"
#import "SFTweetModel.h"

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
@property (nonatomic, retain) NSTimer *keepAliveTimer;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableString *buffer;

@property BOOL shouldRestart;

@end

@implementation SFTwitterStream

- (id)init
{
    self = [super init];
    if (self) {
        
        _queue = [[NSOperationQueue alloc] init];
        _buffer = [[NSMutableString alloc] initWithCapacity:6];
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
    [self.buffer setString: @""];
    [self resetKeepalive];

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

- (void)restartQueue
{
    [self stopQueue];
    [self startQueue];
}

#pragma mark - private helper methods

/*
 Most of the time Tweets arrive one by one
 When more than one Tweet is received,
 Tweets are separated by '\r\n'
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [self.buffer appendString:response];
    
    NSLog(@"%@", response);

    if ([self isValidResponse:self.buffer]) {
        
        for (NSString *tweet in [self.buffer componentsSeparatedByString:@"\r\n"]) {
            if ([tweet length]) {
                [self parseTweet:tweet];
            }
        }

        [self.buffer setString: @""];
    }
}

- (void)parseTweet:(NSString *)tweet
{
    NSData *data = [tweet dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

    if (json && self.dataReceivedBlock){
        [self parseTweetFromJson:json];
    }

    if (!json) {
        NSLog(@" ------------ Failed to parse a tweet: %@", tweet);
    }
}

- (void)parseTweetFromJson:(NSDictionary *)tweetJson
{
    NSString *text = [tweetJson objectForKey:@"text"];
    NSDictionary *user = [tweetJson objectForKey:@"user"];

    if (text && user)
    {
        SFTweetModel *tweet = [[SFTweetModel alloc] init];

        tweet.text = text;
        tweet.userName = [user objectForKey:@"name"];

        // received a valid tweet
        // reset the timer
        [self resetKeepalive];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataReceivedBlock(tweet);
        });
    }
}

- (BOOL)isValidResponse:(NSString *)response
{
    if ([response hasPrefix:@"{"] &&
        ([response hasSuffix:@"}"] || [response hasSuffix:@"}\r\n"]))
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - Keep Alive

- (void)resetKeepalive
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(onNoResponse)
                                               object:NULL];
    
    [self performSelector:@selector(onNoResponse)
               withObject:NULL
               afterDelay:60.0f];
}

- (void)onNoResponse
{
    NSLog(@" ------------ did not receive any tweets for a minute");
    [self restartQueue];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@" ------------ connection failed with error: %@", error.localizedDescription);
    [self restartQueue];
}

@end
