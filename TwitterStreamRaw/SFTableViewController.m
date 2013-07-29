//
//  SFTableViewController.m
//  TwitterStreamRaw
//
//  Created by Sei Feet on 7/25/13.
//  Copyright (c) 2013 Sei Feet. All rights reserved.
//

#import "SFTableViewController.h"
#import "SFTwitterAccountManager.h"
#import "SFAlertHelper.h"
#import "SFTwitterStream.h"
#import "SFTweetModel.h"
#import "SFAppDelegate.h"

#import <Accounts/Accounts.h>

#import "Reachability.h"

@interface SFTableViewController ()
{
}

@property BOOL isRunning;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIButton *goButton;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) SFTwitterStream *trackStream;

@property (nonatomic, strong) NSMutableArray *tweets;

@end

@implementation SFTableViewController


- (void)initCommon
{
    _isRunning = NO;
    _tweets = [[NSMutableArray alloc] initWithCapacity:10];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initCommon];
    }

    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self createViews];

    self.tableView.tableHeaderView = [self tableHeaderView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tweets count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.numberOfLines = 3;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    }

    SFTweetModel *tweet = [self.tweets objectAtIndex:indexPath.section];

    cell.textLabel.text = tweet.userName;
    cell.detailTextLabel.text = tweet.text;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - UITextFieldDelegate protocol
-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];

    [self startAndClear:YES];
    
    return NO; // We do not want UITextField to insert line-breaks.
}


#pragma mark - private helper methods
- (void)createViews
{
    // social
    self.goButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.goButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.goButton setTitle:@"Stop" forState:UIControlStateSelected];
    [self.goButton addTarget:self action:@selector(goSelected:)
            forControlEvents:UIControlEventTouchUpInside];

    self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    self.textField.font = [UIFont systemFontOfSize:15];
    self.textField.placeholder = @"enter text";
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.keyboardType = UIKeyboardTypeDefault;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField.delegate = self;
}

- (UIView *)tableHeaderView
{
    if (!self.headerView) {

        CGFloat width = self.tableView.bounds.size.width;

        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 80.0f)];

        self.goButton.frame = CGRectMake(width - 80.0f, 10.0f, 64.0f, 32.0f);
        self.textField.frame = CGRectMake(10.0f, 10.0f, width - 100.0f, 32.0f);

        [self.headerView addSubview:self.goButton];
        [self.headerView addSubview:self.textField];
    }

    return self.headerView;
}

- (void)startAndClear:(BOOL)clear
{
    if (self.isRunning) {

        [self stop];
    }

    if (self.textField.text.length) {
        
        self.goButton.selected = YES;
        self.isRunning = YES;

        if (clear) {
            [self.tweets removeAllObjects];
            [self.tableView reloadData];
        }
        
        [self startTwitterStreamsWithTerm:self.textField.text];
    }
}

- (void)stop
{
    self.goButton.selected = NO;
    self.isRunning = NO;

    if (self.trackStream) {
        [self.trackStream stop];
    }
}

- (void)startTwitterStreamsWithTerm:(NSString *)term
{
    if (self.trackStream) {

        [self.trackStream startWithTerm:term];
    } else {
        
        [[SFTwitterAccountManager sharedManager] selectAccountWithCompletionBlock:^(id object) {

            if (object && [object isKindOfClass:ACAccount.class]) {

                ACAccount *account = (ACAccount *)object;


                self.trackStream = [[SFTwitterStream alloc] initWithAccount:account controller:@"statuses/filter.json" action:@"track" andDataReceivedBlock:^(id object)
                {
                    if (object && [object isKindOfClass:SFTweetModel.class]) {
                        [self addTweet:object];
                    }
                }];

                [self.trackStream startWithTerm:term];
                
            } else {
                [[SFAlertHelper sharedHelper] noTwitterAccounts];
                [self stop];
            }
        }];
    }
}

- (void)addTweet:(SFTweetModel *)tweet
{
    [self.tableView beginUpdates];

    [self.tweets addObject:tweet];

    [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.tweets.count-1, 1)] withRowAnimation:UITableViewRowAnimationAutomatic];

    [self.tableView endUpdates];
}

#pragma mark - selectors
- (IBAction)goSelected:(id)sender
{
    [self.view endEditing:YES];

    if (self.isRunning) {

        [self stop];
    } else {

        [self startAndClear:YES];
    }
}

-(void) checkNetworkStatus:(NSNotification *)notice
{
    NetworkStatus internetStatus = [SharedAppDelegate.internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            break;
        }
        case ReachableViaWiFi:
        case ReachableViaWWAN:
        {
            if (self.isRunning) {
                [self startAndClear:NO];
            }
            break;
        }
    }
}

@end
