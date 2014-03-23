//
//  SIOClient.h
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIOEventMessage.h"
#import "SIOTextMessage.h"
#import "SIOJSONMessage.h"

@class SIOClient;

typedef NS_ENUM(NSInteger, SIOClientState) {
    SIOClientDisconnectedState,
    SIOClientDisconnectingState,
    SIOClientConnectedState,
    SIOClientConnectingState
};

typedef void(^SIOClientStatusListener)(SIOClient *client, SIOClientState state);
typedef void(^SIOEventListener)(SIOClient *client, SIOClientState state, SIOEventMessage *message);
typedef void(^SIOTextListener)(SIOClient *client, SIOClientState state, SIOTextMessage *message);
typedef void(^SIOJSONListener)(SIOClient *client, SIOClientState state, SIOJSONMessage *message);
typedef void(^SIOAcknoledgementCallback)(NSString *data);

extern NSString *const SIOClientErrorDomain;

extern NSString *const SIOClientWebSocketTransportID;
extern NSString *const SIOClientXHRPollingTransportID; // Unsupported


@protocol SIOClientDelegate <NSObject>

- (void)client:(SIOClient *)client didFailWithError:(NSError *)error;

@optional
- (void)client:(SIOClient *)client didTransitionToState:(SIOClientState)state;

@end


/**
 *  https://github.com/LearnBoost/socket.io-spec
 */
@interface SIOClient : NSObject

// Secure is NO
- (instancetype)initWithHost:(NSString *)host;
- (instancetype)initWithHost:(NSString *)host secure:(BOOL)secure;

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, assign) NSUInteger port;
@property (nonatomic, assign) BOOL secure;

@property (nonatomic, weak) id <SIOClientDelegate> delegate;

@property (nonatomic, assign, readonly) SIOClientState state;

@property (nonatomic, copy) NSString *socketNamespace;
@property (nonatomic, readwrite) NSUInteger protocolVersion;

- (void)connect;
- (void)connectWithSession:(NSString *)session
                 transport:(NSString *)transport
                    params:(NSDictionary *)params;
- (void)disconnect;

- (void)addStatus:(SIOClientState)status listener:(SIOClientStatusListener)listener;
- (void)addEvent:(NSString *)event listener:(SIOEventListener)listener;
- (void)addTextListener:(SIOTextListener)listener;
- (void)addJSONListener:(SIOJSONListener)listener;

- (void)sendMessage:(NSString *)message;
- (void)sendMessage:(NSString *)message callback:(SIOAcknoledgementCallback)callback;
- (void)sendObject:(NSDictionary *)object;
- (void)sendObject:(NSDictionary *)object callback:(SIOAcknoledgementCallback)callback;
- (void)sendEvent:(NSString *)name args:(NSArray *)args;
- (void)sendEvent:(NSString *)name args:(NSArray *)args callback:(SIOAcknoledgementCallback)callback;

@end
