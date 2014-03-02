//
//  SIOErrorMessage.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOErrorMessage.h"

@interface SIOErrorMessage () {
    NSString *_errorReason;
    NSString *_errorAdvice;
}

@end

@implementation SIOErrorMessage

- (SIOMessageType)type
{
    return SIOMessageTypeError;
}

- (NSString *)errorReason
{
    if (self->_errorReason == nil)
    {
        
    }
    return self->_errorReason;
}

- (NSString *)errorAdvice
{
    if (self->_errorAdvice == nil)
    {
        
    }
    return self->_errorAdvice;
}

@end
