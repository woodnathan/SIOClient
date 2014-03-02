//
//  SIOBlockCollection.h
//  socket.io
//
//  Created by Nathan Wood on 11/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIOBlockCollection : NSObject

- (id)addBlock:(id)block forKey:(id <NSCopying>)key;
- (void)removeBlock:(id)block;

- (id <NSFastEnumeration>)blocksForKey:(id)key;

@end
