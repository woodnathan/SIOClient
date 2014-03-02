//
//  SIONoopMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIONoopMessage.h"

@implementation SIONoopMessage

- (SIOMessageType)type
{
    return SIOMessageTypeNoop;
}

@end
