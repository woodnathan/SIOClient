//
//  SIOHeartbeatMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOHeartbeatMessage.h"

@implementation SIOHeartbeatMessage

- (SIOMessageType)type
{
    return SIOMessageTypeHeartbeat;
}

@end
