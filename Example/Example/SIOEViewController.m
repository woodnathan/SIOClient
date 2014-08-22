//
//  SIOEViewController.m
//  Example
//
//  Created by Nathan Wood on 22/08/2014.
//  Copyright (c) 2014 Nathan Wood. All rights reserved.
//

#import "SIOEViewController.h"
#import "SIOClient.h"

@interface SIOEViewController () <SIOClientDelegate>

@property (nonatomic, strong) SIOClient *client;

- (void)handleMessage:(SIOEventMessage *)message;

@end

@implementation SIOEViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        SIOClient *client = [[SIOClient alloc] initWithHost:@"morning-lowlands-5368.herokuapp.com" secure:NO];
//        client.port = 5000;
        client.delegate = self;
        self.client = client;
        
        __weak __typeof(self) weakSelf = self;
        [client addEvent:@"message" listener:^(SIOClient *client, SIOClientState state, SIOEventMessage *message) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            
            [strongSelf handleMessage:message];
        }];
        
        [client addStatus:SIOClientConnectedState listener:^(SIOClient *client, SIOClientState state) {
            NSLog(@"Connected");
            
            [client sendEvent:@"message" args:@[ @"I've connected now!" ]];
        }];
        [client addStatus:SIOClientConnectingState listener:^(SIOClient *client, SIOClientState state) {
            NSLog(@"Connecting");
        }];
        [client addStatus:SIOClientDisconnectedState listener:^(SIOClient *client, SIOClientState state) {
            NSLog(@"Disconnected");
        }];
    }
    return self;
}

- (void)client:(SIOClient *)client didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.client connect];
}

- (void)handleMessage:(SIOEventMessage *)message
{
    NSLog(@"%@", message.args);
}

@end
