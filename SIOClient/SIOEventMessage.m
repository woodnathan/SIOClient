//
//  SIOEventMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOEventMessage.h"

/**
 *  Reserved Event Names:
 *    - message
 *    - connect
 *    - disconnect
 *    - open
 *    - close
 *    - error
 *    - retry
 *    - reconnect
 */

@implementation SIOEventMessage

@synthesize name = _name, args = _args;

- (SIOMessageType)type
{
    return SIOMessageTypeEvent;
}

- (NSString *)name
{
    NSString *name = self->_name;
    if (name == nil)
    {
        NSDictionary *dataObject = self.dataObject;
        if ([dataObject isKindOfClass:[NSDictionary class]])
        {
            name = [dataObject objectForKey:@"name"];
            self->_name = name;
        }
    }
    return name;
}

- (NSArray *)args
{
    NSArray *args = self->_args;
    if (args == nil)
    {
        NSDictionary *dataObject = self.dataObject;
        if ([dataObject isKindOfClass:[NSDictionary class]])
        {
            args = [dataObject objectForKey:@"args"];
            self->_args = args;
        }
    }
    return args;
}

- (NSMutableString *)payload
{
    self.dataObject = [NSDictionary dictionaryWithObjectsAndKeys:self.name, @"name", self.args, @"args", nil];
    return [super payload];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: 0x%x - %@>", NSStringFromClass(self.class), (unsigned int)self, self.name];
}

@end
