//
//  SIOAcknowledgeMessage.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOMessage.h"

@interface SIOAcknowledgeMessage : SIOMessage

@property (nonatomic, assign) NSInteger acknowledgeID;

@end
