//
//  SIOWebSocketTransport.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOWebSocketTransport.h"
#import "SRWebSocket.h"
#import "SIOMessage.h"
#import "SIOHeartbeatMessage.h"

@interface SIOWebSocketTransport () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *socket;

@end

@implementation SIOWebSocketTransport

- (NSString *)schemeSecure:(BOOL)secure
{
    return secure ? @"wss" : @"ws";
}
- (NSString *)transportID
{
    return @"websocket";
}

- (void)dealloc
{
    SRWebSocket *socket = self.socket;
    if (socket != nil)
    {
        socket.delegate = nil;
        [socket close];
    }
}

- (void)connect
{
    SIOTransportState state = self.state;
    if (state == SIOTransportStateOpening || state == SIOTransportStateOpen)
        return;
    
    self->_state = SIOTransportStateOpening;
    [self.delegate transport:self transitionedToState:SIOTransportStateOpening];
    
    NSMutableURLRequest *request = [self.delegate transportRequestWithTransport:self];
    
    SRWebSocket *socket = [[SRWebSocket alloc] initWithURLRequest:request];
    socket.delegate = self;
    self.socket = socket;
    [socket open];
}

- (void)disconnect
{
    SIOTransportState state = self.state;
    if (state == SIOTransportStateClosing || state == SIOTransportStateClosed)
        return;
    
    self->_state = SIOTransportStateClosing;
    [self.socket close];
    
    [self.delegate transport:self transitionedToState:SIOTransportStateClosing];
}

- (BOOL)isReady
{
    return (self.socket.readyState == SR_OPEN);
}

- (BOOL)sendMessage:(SIOMessage *)message
{
    SRWebSocket *socket = self.socket;
    if (socket.readyState != SR_OPEN)
        return NO;
    
    NSString *payload = message.payload;
    [socket send:payload];
    
    return YES;
}

- (void)sendHeartbeat
{
    [self sendMessage:[[SIOHeartbeatMessage alloc] init]];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)data
{
    SIOMessage *message = [[SIOMessage alloc] initWithString:data];
    
    [self.delegate transport:self receivedMessage:message];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self->_state = SIOTransportStateOpen;
    
    [self.delegate transport:self transitionedToState:SIOTransportStateOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self->_state = SIOTransportStateClosed;
    
    [self.delegate transport:self transitionedToState:SIOTransportStateClosed];
    
    [self.delegate transport:self didFailWithError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self->_state = SIOTransportStateClosed;
    
    [self.delegate transport:self transitionedToState:SIOTransportStateClosed];
    
    if (wasClean == NO)
        [self connect];
}

@end
