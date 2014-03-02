//
//  SIOAcknowledgeMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOAcknowledgeMessage.h"

@implementation SIOAcknowledgeMessage

- (SIOMessageType)type
{
    return SIOMessageTypeACK;
}

- (NSInteger)acknowledgeID
{
    if (self->_acknowledgeID == 0)
    {
        self->_acknowledgeID = [self.data integerValue];
    }
    return self->_acknowledgeID;
}

- (NSMutableString *)payload
{
    NSMutableString *payload = [super payload];
    
    [payload appendFormat:@":%d", self.acknowledgeID];
    
    return payload;
}

@end
