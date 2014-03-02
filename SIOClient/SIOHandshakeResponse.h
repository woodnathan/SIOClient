//
//  SIOHandshakeResponse.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIOHandshakeResponse : NSObject

- (instancetype)initWithData:(NSData *)data;

@property (nonatomic, strong, readonly) NSString *session;
@property (nonatomic, assign, readonly) NSInteger heartbeatTimeout;
@property (nonatomic, assign, readonly) NSInteger connectionClosingTimeout;
@property (nonatomic, strong, readonly) NSArray *supportedTransports;

@end
