//
//  SIOMessage.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SIODisconnectMessage;

typedef NS_ENUM(NSInteger, SIOMessageType) {
    SIOMessageTypeUnknown       = -1,
    SIOMessageTypeDisconnect    = 0,
    SIOMessageTypeConnect       = 1,
    SIOMessageTypeHeartbeat     = 2,
    SIOMessageTypeMessage       = 3,
    SIOMessageTypeJSONMessage   = 4,
    SIOMessageTypeEvent         = 5,
    SIOMessageTypeACK           = 6,
    SIOMessageTypeError         = 7,
    SIOMessageTypeNoop          = 8,
};

@interface SIOMessage : NSObject

- (instancetype)initWithString:(NSString *)string;

@property (nonatomic, readonly) SIOMessageType type;
@property (nonatomic, assign) NSInteger messageID;
@property (nonatomic, assign) BOOL acknowledge;
@property (nonatomic, strong) NSString *endpoint;

@property (nonatomic, strong) NSString *data;

@property (nonatomic, readonly) id dataObject; // JSON
@property (nonatomic, readonly) NSString *name; // Event
@property (nonatomic, readonly) NSArray *args; // Event
@property (nonatomic, readonly) NSString *errorReason; // Error
@property (nonatomic, readonly) NSString *errorAdvice; // Error

- (NSMutableString *)payload;

@end
