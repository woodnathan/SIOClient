//
//  SIOHandshakeResponse.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOHandshakeResponse.h"

@interface SIOHandshakeResponse ()

@property (nonatomic, strong, readwrite) NSString *session;
@property (nonatomic, assign, readwrite) NSInteger heartbeatTimeout;
@property (nonatomic, assign, readwrite) NSInteger connectionClosingTimeout;
@property (nonatomic, strong, readwrite) NSArray *supportedTransports;

- (BOOL)parseHandshakeResponse:(NSString *)response;

@end

@implementation SIOHandshakeResponse

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self parseHandshakeResponse:response];
    }
    return self;
}

- (BOOL)parseHandshakeResponse:(NSString *)response
{
    NSScanner *scanner = [[NSScanner alloc] initWithString:response];
    scanner.charactersToBeSkipped = nil;
    
    NSString *sessionID = nil;
    NSInteger heartbeatTimeout = 0;
    NSInteger connectionClosingTimeout = 0;
    NSMutableArray *supportedTransports = [[NSMutableArray alloc] init];
    
    NSCharacterSet *colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSCharacterSet *commaSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    
    [scanner scanUpToCharactersFromSet:colonSet intoString:&sessionID];
    [scanner scanCharactersFromSet:colonSet intoString:nil];
    [scanner scanInteger:&heartbeatTimeout];
    [scanner scanCharactersFromSet:colonSet intoString:nil];
    [scanner scanInteger:&connectionClosingTimeout];
    [scanner scanCharactersFromSet:colonSet intoString:nil];
    
    NSString *transport = nil;
    while ([scanner isAtEnd] == NO)
    {
        [scanner scanUpToCharactersFromSet:commaSet intoString:&transport];
        [scanner scanCharactersFromSet:commaSet intoString:nil];
        [supportedTransports addObject:transport];
    }
    
    self.session = sessionID;
    self.heartbeatTimeout = heartbeatTimeout;
    self.connectionClosingTimeout = connectionClosingTimeout;
    self.supportedTransports = [supportedTransports copy];
    
    return YES;
}

@end
