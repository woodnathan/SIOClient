//
//  SIOTransport.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIOMessage.h"

typedef NS_ENUM(NSInteger, SIOTransportState) {
    SIOTransportStateClosed,
    SIOTransportStateClosing,
    SIOTransportStateOpen,
    SIOTransportStateOpening
};

@protocol SIOTransport <NSObject>

@property (nonatomic, readonly, getter = isReady) BOOL ready;

- (void)connect;

- (BOOL)sendMessage:(SIOMessage *)message;
- (void)sendHeartbeat;

- (NSString *)schemeSecure:(BOOL)secure;
- (NSString *)transportID;

@end

@protocol SIOTransportDelegate <NSObject>

- (NSMutableURLRequest *)transportRequestWithTransport:(id <SIOTransport>)transport;

- (void)transport:(id <SIOTransport>)transport transitionedToState:(SIOTransportState)state;
- (void)transport:(id <SIOTransport>)transport receivedMessage:(SIOMessage *)message;
- (void)transport:(id <SIOTransport>)transport didFailWithError:(NSError *)error;

@end

@interface SIOTransport : NSObject {
  @protected
    SIOTransportState _state;
}

- (instancetype)initWithDelegate:(id <SIOTransportDelegate>)delegate;

@property (nonatomic, weak) id <SIOTransportDelegate> delegate;

@property (nonatomic, readonly) SIOTransportState state;

@end
