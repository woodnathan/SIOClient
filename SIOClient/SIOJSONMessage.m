//
//  SIOJSONMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOJSONMessage.h"

@implementation SIOJSONMessage

@synthesize dataObject = _dataObject;

- (SIOMessageType)type
{
    return SIOMessageTypeJSONMessage;
}

- (id)dataObject
{
    id dataObject = self->_dataObject;
    if (dataObject == nil)
    {
        NSData *data = [self.data dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil)
        {
            dataObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            self.dataObject = dataObject;
        }
    }
    return dataObject;
}

- (NSMutableString *)payload
{
    NSMutableString *payload = [super payload];
    
    id dataObject = self.dataObject;
    if (dataObject)
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataObject options:0 error:nil];
        if (data)
        {
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [payload appendFormat:@":%@", string];
        }
    }
    
    return payload;
}

@end
