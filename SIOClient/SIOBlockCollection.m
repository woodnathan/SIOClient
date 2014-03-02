//
//  SIOBlockCollection.m
//  socket.io
//
//  Created by Nathan Wood on 11/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOBlockCollection.h"

@interface SIOBlockObject : NSObject

+ (instancetype)objectWithKey:(id)key block:(id)block;

@property (nonatomic, strong) id key;
@property (nonatomic, strong) id block;

@end

@interface SIOBlockCollection ()

@property (nonatomic, strong) NSMutableDictionary *dictionary;

@end

@implementation SIOBlockCollection

@synthesize dictionary = _dictionary;

- (NSMutableDictionary *)dictionary
{
    if (self->_dictionary == nil)
        self->_dictionary = [[NSMutableDictionary alloc] init];
    return self->_dictionary;
}

#pragma mark - 

- (id)addBlock:(id)block forKey:(id <NSCopying>)key
{
    NSMutableDictionary *dictionary = self.dictionary;
    NSMutableSet *set = [dictionary objectForKey:key];
    if (set == nil)
    {
        set = [[NSMutableSet alloc] init];
        [dictionary setObject:set forKey:key];
    }
    
    [set addObject:block];
    
    return [SIOBlockObject objectWithKey:key block:block];
}

- (void)removeBlock:(id)block
{
    if ([block isKindOfClass:[SIOBlockObject class]])
    {
        SIOBlockObject *obj = block;
        NSMutableSet *set = [self.dictionary objectForKey:obj.key];
        [set removeObject:obj.block];
    }
}

#pragma mark -

- (id <NSFastEnumeration>)blocksForKey:(id)key
{
    return [self.dictionary objectForKey:key];
}

@end

@implementation SIOBlockObject

@synthesize key = _key, block = _block;

+ (instancetype)objectWithKey:(id)key block:(id)block
{
    SIOBlockObject *obj = [[SIOBlockObject alloc] init];
    obj.key = key;
    obj.block = block;
    return obj;
}

@end