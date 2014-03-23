//
//  SIOXHRPollingTransport.m
//  socket.io
//
//  Created by Nathan Wood on 23/03/2014.
//  Copyright (c) 2014 Nathan Wood. All rights reserved.
//

#import "SIOXHRPollingTransport.h"

NSString *const SIOXHRFrame = @"\ufffd";

@interface SIOXHRPollingTransport () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readonly) NSOperationQueue *queue;

@property (nonatomic, copy) NSURLRequest *baseRequest;

@property (nonatomic, readonly) NSMutableArray *messages;

@property (atomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSOutputStream *outputStream;

@end

@implementation SIOXHRPollingTransport

@synthesize queue = _queue;
@synthesize baseRequest = _baseRequest;
@synthesize messages = _messages;
@synthesize connection = _connection;
@synthesize outputStream = _outputStream;

- (instancetype)initWithDelegate:(id<SIOTransportDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.name = NSStringFromClass([self class]);
        self->_queue = queue;
        
        self->_messages = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark SIOTransport

- (NSString *)schemeSecure:(BOOL)secure
{
    return secure ? @"https" : @"http";
}

+ (NSString *)transportID
{
    return @"xhr-polling";
}

- (NSString *)transportID
{
    return @"xhr-polling";
}

- (BOOL)isReady
{
    return YES;
}

- (void)connect
{
    SIOTransportState state = self.state;
    if (state == SIOTransportStateOpening || state == SIOTransportStateOpen)
        return;
    
    self->_state = SIOTransportStateOpening;
    [self.delegate transport:self transitionedToState:SIOTransportStateOpening];
    
    NSMutableURLRequest *baseRequest = [self.delegate transportRequestWithTransport:self params:nil];
    [baseRequest setValue:@"close" forHTTPHeaderField:@"Connection"];
//    [baseRequest setValue:@"timeout=30" forHTTPHeaderField:@"Keep-Alive"];
    self.baseRequest = baseRequest;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self poll];
    });
}

- (void)disconnect
{
    SIOTransportState state = self.state;
    if (state == SIOTransportStateClosing || state == SIOTransportStateClosed)
        return;
    
    self->_state = SIOTransportStateClosing;
    [self.delegate transport:self transitionedToState:SIOTransportStateClosing];
    
    NSMutableURLRequest *request = [self.delegate transportRequestWithTransport:self params:@{ @"disconnect" : @"" }];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               dispatch_sync(dispatch_get_main_queue(), ^{
                                   self->_state = SIOTransportStateClosed;
                                   [self.delegate transport:self transitionedToState:SIOTransportStateClosed];
                               });
                           }];
}

- (BOOL)sendMessage:(SIOMessage *)message
{
    if (message == nil)
        return NO;
    
    [self.messages addObject:[message copy]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self poll];
    });
    
    return YES; // Can't guarantee that it's sent yet
}

#pragma mark Polling

- (void)poll
{
    if (self.connection != nil || (self.state == SIOTransportStateClosed || self.state == SIOTransportStateClosing))
        return;
    
    NSArray *messages = [self.messages copy];
    [self.messages removeAllObjects]; // Need to look at locking this
    NSData *requestBody = nil;
    if (messages.count > 0)
    {
        NSString *payloadString = nil;
        if (messages.count == 1)
        {
            payloadString = [[[messages lastObject] payload] copy];
        }
        else
        {
            NSMutableArray *payloadComponents = [[NSMutableArray alloc] init];
            for (SIOMessage *message in messages)
            {
                NSString *messagePayload = [message.payload copy];
                [payloadComponents addObject:@(messagePayload.length)];
                [payloadComponents addObject:messagePayload];
            }
            
            // \ufffd[payload[0] length]\ufffd\[payload[0]]\ufffd[payload[n] length]\ufffd\[payload[n]]
            payloadString = [SIOXHRFrame stringByAppendingString:[payloadComponents componentsJoinedByString:SIOXHRFrame]];
        }
        requestBody = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    // Need to look at updating the time (t) query string value
    NSMutableURLRequest *request = [self.baseRequest mutableCopy];
    if (requestBody)
    {
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestBody];
        [request setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    self.connection = connection;
    NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
    [outputStream open];
    self.outputStream = outputStream;
    [connection setDelegateQueue:self.queue];
    [connection start];
}

#pragma mark Messages

- (NSArray *)messagesWithData:(NSData *)data
{
    NSArray *responseMessages = nil;
    
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([response hasPrefix:SIOXHRFrame])
    {
        NSScanner *scanner = [[NSScanner alloc] initWithString:response];
        NSCharacterSet *frameSet = [NSCharacterSet characterSetWithCharactersInString:SIOXHRFrame];
        
        NSMutableArray *messages = [[NSMutableArray alloc] init];
        while ([scanner isAtEnd] == NO)
        {
            [scanner scanCharactersFromSet:frameSet intoString:nil];
            
            if ([scanner scanInt:NULL] == NO)
                break; // Something went wrong
            
            [scanner scanCharactersFromSet:frameSet intoString:nil];
            
            NSString *messageData = nil;
            if ([scanner scanUpToCharactersFromSet:frameSet intoString:&messageData] == NO)
                break;
            
            SIOMessage *message = [[SIOMessage alloc] initWithString:messageData];
            if (message != nil)
                [messages addObject:message];
        }
        responseMessages = [messages copy];
    }
    else
    {
        responseMessages = [NSArray arrayWithObjects:[[SIOMessage alloc] initWithString:response], nil];
    }
    return responseMessages;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.state != SIOTransportStateOpen)
        {
            self->_state = SIOTransportStateOpen;
            
            [self.delegate transport:self transitionedToState:SIOTransportStateOpen];
        }
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.outputStream write:(const uint8_t *)data.bytes maxLength:data.length];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.outputStream = nil;
        self.connection = nil;
        
        self->_state = SIOTransportStateClosed;
        
        [self.delegate transport:self transitionedToState:SIOTransportStateClosed];
        
        [self.delegate transport:self didFailWithError:error];
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSData *responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.outputStream = nil;
        self.connection = nil;
    });
    
    NSArray *messages = [self messagesWithData:responseData];
    for (SIOMessage *message in messages)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate transport:self receivedMessage:message];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.state == SIOTransportStateOpen)
            [self poll];
    });
}

@end
