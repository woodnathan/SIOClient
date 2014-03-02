//
//  SIOTextMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOTextMessage.h"

@implementation SIOTextMessage

- (SIOMessageType)type
{
    return SIOMessageTypeMessage;
}

- (NSMutableString *)payload
{
    NSMutableString *payload = [super payload];
    
    NSString *data = self.data;
    if (data)
        [payload appendFormat:@"%@", data];
    
    return payload;
}

@end
