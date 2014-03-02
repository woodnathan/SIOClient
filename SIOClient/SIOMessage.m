//
//  SIOMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOMessage.h"
#import "SIODisconnectMessage.h"
#import "SIOConnectMessage.h"
#import "SIOHeartbeatMessage.h"
#import "SIOTextMessage.h"
#import "SIOJSONMessage.h"
#import "SIOEventMessage.h"
#import "SIOAcknowledgeMessage.h"
#import "SIOErrorMessage.h"
#import "SIONoopMessage.h"

static Class SIOMessageClassForType(SIOMessageType type)
{
    switch (type)
    {
        case SIOMessageTypeDisconnect:
            return [SIODisconnectMessage class];
        case SIOMessageTypeConnect:
            return [SIOConnectMessage class];
        case SIOMessageTypeHeartbeat:
            return [SIOHeartbeatMessage class];
        case SIOMessageTypeMessage:
            return [SIOTextMessage class];
        case SIOMessageTypeJSONMessage:
            return [SIOJSONMessage class];
        case SIOMessageTypeEvent:
            return [SIOEventMessage class];
        case SIOMessageTypeACK:
            return [SIOAcknowledgeMessage class];
        case SIOMessageTypeError:
            return [SIOErrorMessage class];
        case SIOMessageTypeNoop:
            return [SIONoopMessage class];
        default:
            break;
    }
    return Nil;
}

@interface SIOMessage ()

- (NSInteger)parseMessageType:(NSScanner *)scanner;
- (void)parseMessage:(NSScanner *)scanner;

@end

@implementation SIOMessage

@synthesize messageID = _messageID, acknowledge = _acknowledge;
@synthesize endpoint = _endpoint;

- (instancetype)initWithString:(NSString *)string
{
    self = [super init];
    if (self)
    {
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        SIOMessageType type = [self parseMessageType:scanner];
        Class messageClass = SIOMessageClassForType(type);
        if (messageClass == Nil)
            return nil;
        
        SIOMessage *message = [[messageClass alloc] init];
        [message parseMessage:scanner];
        return message;
    }
    return self;
}

- (NSInteger)parseMessageType:(NSScanner *)scanner
{
    NSInteger type = SIOMessageTypeUnknown;
    [scanner scanInteger:&type];
    return type;
}

- (void)parseMessage:(NSScanner *)scanner
{
    static NSCharacterSet *colonSet = nil;
    static NSCharacterSet *plusSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
        plusSet = [NSCharacterSet characterSetWithCharactersInString:@"+"];
    });
    
    // Skip colon after type
    scanner.scanLocation += 1;
    
    // Scan message ID
    NSInteger messageID = 0;
    BOOL acknowledge = NO;
    [scanner scanInteger:&messageID];
    acknowledge = [scanner scanCharactersFromSet:plusSet intoString:nil];
    scanner.scanLocation += 1;
    
    // Scan endpoint
    NSString *endpoint = nil;
    [scanner scanUpToCharactersFromSet:colonSet intoString:&endpoint];
    
    // Scan data
    NSString *data = nil;
    if ([scanner isAtEnd] == NO)
    {
        [scanner scanCharactersFromSet:colonSet intoString:nil];
        data = [scanner.string substringFromIndex:scanner.scanLocation];
    }
    
    self->_messageID = messageID;
    self->_acknowledge = acknowledge;
    self->_endpoint = endpoint;
    self->_data = data;
}

- (SIOMessageType)type
{
    return SIOMessageTypeUnknown;
}

- (id)dataObject
{
    return nil;
}

- (NSString *)name
{
    return nil;
}

- (NSArray *)args
{
    return nil;
}

- (NSString *)errorReason
{
    return nil;
}

- (NSString *)errorAdvice
{
    return nil;
}

- (NSMutableString *)payload
{
    NSMutableString *payload = [[NSMutableString alloc] initWithFormat:@"%i", self.type];
    
    NSInteger messageID = self.messageID;
    if (messageID != 0)
    {
        [payload appendFormat:@":%i", messageID];
        
        if (self.acknowledge)
            [payload appendString:@"+"];
    }
    else
    {
        [payload appendString:@":"];
    }
    
    NSString *endpoint = self.endpoint;
    if (endpoint != nil)
    {
        [payload appendFormat:@":%@", endpoint];
    }
    else
    {
        [payload appendString:@":"];
    }
    
    return payload;
}

@end
