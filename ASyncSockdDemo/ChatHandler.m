//
//  ChatHandler.m
//  ASyncSockdDemo
//
//  Created by stoicer on 2022/9/26.
//

#import "ChatHandler.h"
#define HEART_BEAT_PER_SECOND 1
#define HEART_BEAT_RETRY_COUNTT 3
#define HEART_BEAT_INDENTIFIER @"POHB"


@interface ChatHandler()<GCDAsyncSocketDelegate>
@end
@implementation ChatHandler

static ChatHandler *manager = nil;

+ (instancetype )shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [ChatHandler new];
    });
    
    return manager;
}

- (NSMutableArray *)delegateArray
{
    if (_delegateArray == nil) {
        _delegateArray = [NSMutableArray array];
    }
    
    return _delegateArray;
}

- (void)createSocket
{
    dispatch_queue_t gcdQueue = dispatch_queue_create("gcdQueue", NULL);
    self.client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:gcdQueue];
    [self connectToServer];

}

- (void)connectToServer
{
    //开始可连接
    NSError *err = nil;
    [self.client connectToHost:@"localhost" onPort:9999 error:&err];
    if (err)
    {
        NSLog(@"连接失败:%@",[err description]);
    }
    
    NSLog(@"连接成功");
}

- (void)createHeartTimer
{
    dispatch_queue_t queue = dispatch_queue_create("gcd", NULL);
    self.heartBeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * HEART_BEAT_PER_SECOND));
    
    dispatch_source_set_timer(self.heartBeatTimer, time, 1, 0);
    
    dispatch_source_set_event_handler(self.heartBeatTimer, ^{
        
        self.heartBeatCount++;
        
        if (self.heartBeatCount < 3) {
            //发送心跳包
            NSString *hbStr = [NSString stringWithFormat:@"%@/r/n",HEART_BEAT_INDENTIFIER];
            NSData *data=[hbStr dataUsingEncoding:NSUTF8StringEncoding];
            [self.client writeData:data withTimeout:-1 tag:0];
        }
        else
        {
            NSLog(@"socket连接断开");
            self.isConnected = NO;
        }
    });
    
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"connect success.");
    self.isConnected = YES;
    [self.client readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"did nott connect with error:%@",[err description]);
    
    self.heartBeatCount = 0;
    
    //断开后重连
    if (self.retryCount < HEART_BEAT_RETRY_COUNTT) {
        [self connectToServer];
    }
    else
    {
        NSLog(@"重连次数超过规定次数");
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"rece data:%@",str);
    
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //接收到服务器的心跳
    if ([str isEqualToString:HEART_BEAT_INDENTIFIER])
    {
        
        //接到服务器心跳次数置为0
        self.heartBeatCount = 0;
        NSLog(@"------------------接收到服务器心跳-------------------");
        return;
    }
    
  
    //消息分发,将消息发送至每个注册的Object中 , 进行相应的布局等操作
    for (id delegate in self.delegateArray)
    {
        if ([delegate respondsToSelector:@selector(recvMsg:)]) {
            [delegate recvMsg:data];
        }
    }
}


- (void)addChatDelegate:(id<ChatHanderDelegeate>)delegate
{
    if ([self.delegateArray containsObject:delegate] == NO) {
        [self.delegateArray addObject:delegate];
    }
}

- (void)removeChatDelegate:(id<ChatHanderDelegeate>)delegate
{
    [self.delegateArray removeObject:delegate];
}

- (void)sendMessageWitchModel:(id)model
{
    
}

@end
