//
//  SIOConnectMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOConnectMessage.h"

@implementation SIOConnectMessage

- (SIOMessageType)type
{
    return SIOMessageTypeConnect;
}

@end
