//
//  SIOJSONMessage.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOMessage.h"

@interface SIOJSONMessage : SIOMessage

@property (nonatomic, strong) id dataObject;

@end
