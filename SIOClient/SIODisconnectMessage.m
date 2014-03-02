//
//  SIODisconnectMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIODisconnectMessage.h"

@implementation SIODisconnectMessage

- (SIOMessageType)type
{
    return SIOMessageTypeDisconnect;
}

@end
