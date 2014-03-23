//
//  SIOClient.m
//  socket.io
//
//  Created by Nathan Wood on 10/11/2013.
//  Copyright (c) 2013 Nathan Wood. All rights reserved.
//

#import "SIOClient.h"
#import "SIOBlockCollection.h"
#import "SIOWebSocketTransport.h"
#import "SIOHandshakeResponse.h"
#import "SIOEventMessage.h"
#import "SIOJSONMessage.h"
#import "SIOTextMessage.h"
#import "SIOAcknowledgeMessage.h"
#import "SIODisconnectMessage.h"

NSString *const SIOClientErrorDomain = @"io.socket.client";

NSString *const SIOClientWebSocketTransportID = @"websocket";
NSString *const SIOClientXHRPollingTransportID = @"xhr-polling";

static NSString *const SIOClientHTTPScheme = @"http";
static NSString *const SIOClientHTTPSScheme = @"https";

static inline BOOL SIOClientIsConnecting(SIOClientState state)
{
    return (state == SIOClientConnectingState || state == SIOClientConnectedState);
}

static NSString *SIOPercentEscapedQueryStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
    static NSString * const SIOCharactersToBeEscaped = @":/?&=;+!@#$()',*";
    static NSString * const SIOCharactersToLeaveUnescaped = @"[].";
    
	return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)SIOCharactersToLeaveUnescaped, (__bridge CFStringRef)SIOCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding)));
}

static NSString *SIOQueryStringFromParametersWithEncoding(NSDictionary *params, NSStringEncoding encoding)
{
    NSMutableArray *pairs = [[NSMutableArray alloc] initWithCapacity:params.count];
    for (NSString *key in params)
    {
        NSString *value = [params objectForKey:key];
        
        NSString *escapedKey = SIOPercentEscapedQueryStringWithEncoding(key, encoding);
        NSString *escapedValue = SIOPercentEscapedQueryStringWithEncoding(value, encoding);
        
        NSString *pair = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];
        [pairs addObject:pair];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

#pragma mark - Extension

@interface SIOClient () <SIOTransportDelegate>

@property (nonatomic, assign, readwrite) SIOClientState state;

@property (nonatomic, strong) SIOHandshakeResponse *handshakeResponse;
@property (nonatomic, strong) SIOTransport <SIOTransport> *transport;

@property (nonatomic, assign) NSInteger messageID;
@property (nonatomic, readonly) SIOBlockCollection *statusListeners;
@property (nonatomic, readonly) SIOBlockCollection *eventListeners;
@property (nonatomic, readonly) NSMutableDictionary *callbacks;

@property (nonatomic, strong) NSRecursiveLock *queueLock;
@property (nonatomic, strong) NSMutableArray *messageQueue;
- (void)addMessageToQueue:(SIOMessage *)message;
- (void)flushQueue:(BOOL)wait;

- (NSMutableURLRequest *)handshakeRequestWithSession:(NSString *)session
                                           transport:(NSString *)transport
                                              params:(NSDictionary *)params;

- (void)openTransport;

@end

#pragma mark - Implementation

@implementation SIOClient

@synthesize statusListeners = _statusListeners, eventListeners = _eventListeners;
@synthesize callbacks = _callbacks;

- (instancetype)initWithHost:(NSString *)host
{
    return [self initWithHost:host secure:NO];
}

- (instancetype)initWithHost:(NSString *)host secure:(BOOL)secure
{
    self = [super init];
    if (self)
    {
        self.state = SIOClientDisconnectedState;
        
        self->_host = [host copy];
        self.secure = secure;
        
        self.messageID = 1;
        
        self.messageQueue = [[NSMutableArray alloc] init];
        self.queueLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - Properties

- (NSUInteger)protocolVersion
{
    return 1;
}

- (NSString *)socketNamespace
{
    if (self->_socketNamespace == nil)
        self.socketNamespace = @"socket.io";
    return self->_socketNamespace;
}

- (SIOBlockCollection *)statusListeners
{
    if (self->_statusListeners == nil)
        self->_statusListeners = [[SIOBlockCollection alloc] init];
    return self->_statusListeners;
}

- (SIOBlockCollection *)eventListeners
{
    if (self->_eventListeners == nil)
        self->_eventListeners = [[SIOBlockCollection alloc] init];
    return self->_eventListeners;
}

- (NSMutableDictionary *)callbacks
{
    if (self->_callbacks == nil)
        self->_callbacks = [[NSMutableDictionary alloc] init];
    return self->_callbacks;
}

- (void)setState:(SIOClientState)state
{
    if (self->_state != state)
    {
        self->_state = state;
        
        [self flushQueue:YES];
        
        if ([self.delegate respondsToSelector:@selector(client:didTransitionToState:)])
            [self.delegate client:self didTransitionToState:state];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (SIOClientStatusListener listener in [self.statusListeners blocksForKey:@(state)])
            {
                listener(self, state);
            }
        });
    }
}

- (void)dispatchEvent:(SIOEventMessage *)message state:(SIOClientState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (SIOEventListener listener in [self.eventListeners blocksForKey:message.name])
        {
            listener(self, state, message);
        }
    });
}

#pragma mark - Connecting

- (void)connect
{
    [self connectWithSession:nil transport:nil params:nil];
}

- (void)connectWithSession:(NSString *)session
                 transport:(NSString *)transport
                    params:(NSDictionary *)params
{
    if (SIOClientIsConnecting(self.state))
        return;
    
    self.state = SIOClientConnectingState;
    
    NSMutableURLRequest *request = [self handshakeRequestWithSession:session
                                                           transport:transport
                                                              params:params];
    
    void(^completion)(NSURLResponse *, NSData *, NSError *) = nil;
    completion = ^(NSURLResponse *response, NSData *data, NSError *error) {
        NSInteger statusCode = 1;
        if ([response respondsToSelector:@selector(statusCode)])
            statusCode = [(id)response statusCode];
        
        if (statusCode == 200)
        {
            SIOHandshakeResponse *handshake = [[SIOHandshakeResponse alloc] initWithData:data];
            self.handshakeResponse = handshake;
            
            // According to the spec, it's considered connected by now
            self.state = SIOClientConnectedState;
            
            [self openTransport];
        }
        else
        {
            self.state = SIOClientDisconnectedState;
            
            NSError *clientError = error;
            if (data.length != 0)
            {
                NSString *description = [[NSString alloc] initWithData:data
                                                              encoding:NSUTF8StringEncoding]; // Should really check the response for encoding
                NSDictionary *userInfo = nil;
                if (error == nil)
                    userInfo = @{ NSLocalizedDescriptionKey : description };
                else
                    userInfo = @{ NSLocalizedDescriptionKey : description, NSUnderlyingErrorKey : error };
                
                clientError = [NSError errorWithDomain:SIOClientErrorDomain
                                                  code:(-statusCode)
                                              userInfo:userInfo];
                
            }
            [self.delegate client:self didFailWithError:clientError];
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:completion];
}

- (void)disconnect
{
    [self.transport sendMessage:[[SIODisconnectMessage alloc] init]];
}

#pragma mark - Transport

- (void)openTransport
{
    SIOTransport <SIOTransport> *transport = [[SIOWebSocketTransport alloc] initWithDelegate:self];
    self.transport = transport;
    
    [transport connect];
}

- (void)addStatus:(SIOClientState)status listener:(SIOClientStatusListener)listener
{
    if (listener)
        [self.statusListeners addBlock:listener forKey:@(status)];
}

- (void)addEvent:(NSString *)event listener:(SIOEventListener)listener
{
    if (listener)
        [self.eventListeners addBlock:listener forKey:event];
}

- (void)send:(SIOMessage *)message withCallback:(SIOAcknoledgementCallback)callback
{
    NSUInteger messageID = self.messageID++;
    
    message.messageID = messageID;
    
    if (callback != nil)
    {
        message.acknowledge = YES;
        [self.callbacks setObject:callback forKey:@(messageID)];
    }
    
    if ([self.transport sendMessage:message] == NO)
        [self addMessageToQueue:message];
}

- (void)sendMessage:(NSString *)data
{
    [self sendMessage:data callback:nil];
}

- (void)sendMessage:(NSString *)data callback:(SIOAcknoledgementCallback)callback
{
    SIOTextMessage *message = [[SIOTextMessage alloc] init];
    message.data = data;
    [self send:message withCallback:callback];
}

- (void)sendAcknowledgement:(NSInteger)acknowledgeID
{
    SIOAcknowledgeMessage *message = [[SIOAcknowledgeMessage alloc] init];
    message.acknowledgeID = acknowledgeID;
    [self send:message withCallback:nil];
}

- (void)sendObject:(NSDictionary *)object
{
    [self sendObject:object callback:nil];
}

- (void)sendObject:(NSDictionary *)object callback:(SIOAcknoledgementCallback)callback
{
    SIOJSONMessage *message = [[SIOJSONMessage alloc] init];
    message.dataObject = object;
    [self send:message withCallback:callback];
}

- (void)sendEvent:(NSString *)name args:(NSArray *)args
{
    [self sendEvent:name args:args callback:nil];
}

- (void)sendEvent:(NSString *)name args:(NSArray *)args callback:(SIOAcknoledgementCallback)callback
{
    SIOEventMessage *message = [[SIOEventMessage alloc] init];
    message.name = name;
    message.args = args;
    [self send:message withCallback:callback];
}

- (void)transport:(id <SIOTransport>)transport receivedMessage:(SIOMessage *)message
{
    switch (message.type)
    {
        case SIOMessageTypeHeartbeat:{
            [self.transport sendHeartbeat];
            break;
        }
        case SIOMessageTypeEvent:{
            [self dispatchEvent:(SIOEventMessage *)message state:self.state];
            break;
        }
        case SIOMessageTypeACK:{
            NSInteger ackID = [(SIOAcknowledgeMessage *)message acknowledgeID];
            SIOAcknoledgementCallback callback = [self.callbacks objectForKey:@(ackID)];
            if (callback)
                callback(message.data);
            break;
        }
        default:
            break;
    }
    
    if (message.acknowledge)
        [self sendAcknowledgement:message.messageID];
    
    [self flushQueue:NO];
}

- (void)transport:(id<SIOTransport>)transport transitionedToState:(SIOTransportState)state
{
    if ([transport isReady])
        [self flushQueue:YES];
}

- (void)transport:(id <SIOTransport>)transport didFailWithError:(NSError *)error
{
    [self.delegate client:self didFailWithError:error];
}

#pragma mark - Queue

- (void)addMessageToQueue:(SIOMessage *)message
{
    NSRecursiveLock *queueLock = self.queueLock;
    [queueLock lock];
    [self.messageQueue addObject:message];
    [queueLock unlock];
}

- (void)flushQueue:(BOOL)wait
{
    NSMutableArray *messageQueue = self.messageQueue;
    SIOTransport <SIOTransport> *transport = self.transport;
    if (messageQueue.count == 0 || [transport isReady] == NO)
        return;
    
    NSRecursiveLock *queueLock = self.queueLock;
    
    void(^sendMessages)(void) = ^(void) {
        @autoreleasepool {
            NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
            NSUInteger idx = 0;
            for (SIOMessage *message in messageQueue)
            {
                if ([transport sendMessage:message])
                    [indexesToRemove addIndex:idx];
                idx++;
            }
            [messageQueue removeObjectsAtIndexes:indexesToRemove];
        }
    };
    
    if (wait)
    {
        [queueLock lock];
        sendMessages();
        [queueLock unlock];
    }
    else
        if ([queueLock tryLock])
        {
            sendMessages();
            [queueLock unlock];
        }
}

#pragma mark - Transport

- (NSMutableURLRequest *)transportRequestWithTransport:(id <SIOTransport>)transport
{
    SIOHandshakeResponse *handshake = self.handshakeResponse;
    
    NSString *scheme = [transport schemeSecure:self.secure];
    NSString *host = self.host;
    NSUInteger port = self.port;
    NSString *namespace = self.socketNamespace;
    NSInteger version = self.protocolVersion;
    NSString *transportID = [transport transportID];
    NSString *session = handshake.session;
    
    if (port == 0)
        port = 80;
    
    NSInteger estLength = 2 * (scheme.length +
                               host.length +
                               namespace.length +
                               transportID.length +
                               session.length);
    
    NSMutableString *URLString = [[NSMutableString alloc] initWithCapacity:estLength];
    
    [URLString appendFormat:@"%@://", scheme];
    [URLString appendString:host];
    [URLString appendFormat:@":%lu", (unsigned long)port];
    [URLString appendString:@"/"];
    [URLString appendFormat:@"%@/", namespace];
    [URLString appendFormat:@"%ld/", (long)version];
    if (transportID)
        [URLString appendFormat:@"%@/", transportID];
    if (session)
        [URLString appendFormat:@"%@/", session];
    
    NSURL *URL = [[NSURL alloc] initWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    return request;
}

#pragma mark - Handshake Request

- (NSMutableURLRequest *)handshakeRequestWithSession:(NSString *)session
                                           transport:(NSString *)transport
                                              params:(NSDictionary *)params
{
    NSMutableDictionary *parameters = [params mutableCopy];
    if (parameters == nil)
        parameters = [[NSMutableDictionary alloc] initWithCapacity:1];
    NSString *timestamp = [NSString stringWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970]];
    [parameters setObject:timestamp forKey:@"t"];
    
    NSString *scheme = self.secure ? SIOClientHTTPSScheme : SIOClientHTTPScheme;
    NSString *host = self.host;
    NSUInteger port = self.port;
    NSString *namespace = self.socketNamespace;
    NSInteger version = self.protocolVersion;
    NSString *query = SIOQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
    
    NSInteger estLength = 2 * (scheme.length +
                               host.length +
                               namespace.length +
                               transport.length +
                               session.length +
                               query.length);
    
    NSMutableString *URLString = [[NSMutableString alloc] initWithCapacity:estLength];
    
    [URLString appendFormat:@"%@://", scheme];
    [URLString appendString:host];
    if (port != 0)
        [URLString appendFormat:@":%lu", (unsigned long)port];
    [URLString appendString:@"/"];
    [URLString appendFormat:@"%@/", namespace];
    [URLString appendFormat:@"%ld/", (long)version];
    if (transport)
        [URLString appendFormat:@"%@/", transport];
    if (session)
        [URLString appendFormat:@"%@/", session];
    if (query)
        [URLString appendFormat:@"?%@", query];
    
    NSURL *URL = [[NSURL alloc] initWithString:URLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    return request;
}

@end
