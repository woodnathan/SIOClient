//
//  SIOTransport.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOTransport.h"

@implementation SIOTransport

- (instancetype)initWithDelegate:(id <SIOTransportDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self->_state = SIOTransportStateClosed;
        
        self.delegate = delegate;
    }
    return self;
}

@end
