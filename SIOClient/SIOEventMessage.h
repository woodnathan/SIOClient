//
//  SIOEventMessage.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOJSONMessage.h"

@interface SIOEventMessage : SIOJSONMessage

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *args;

@end
