//
//  ViewController.m
//  ASyncSockdDemo
//
//  Created by stoicer on 2022/9/26.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>

/** client */
@property (nonatomic, strong) GCDAsyncSocket *client;

/** 是否已连接  */
@property (nonatomic, assign) BOOL isConnected;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isConnected = NO;
    dispatch_queue_t gcdQueue = dispatch_queue_create("gcdQueue", NULL);
    self.client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:gcdQueue];
    
    //开始可连接
    NSError *err = nil;
    [self.client connectToHost:@"localhost" onPort:9999 error:&err];
    if (err)
    {
        NSLog(@"连接失败:%@",[err description]);
    }
    NSLog(@"连接成功");
    
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
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"rece data:%@",str);
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.isConnected)
    {
        NSString *str = @"abcd\r\n";
        [self.client writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
        [self.client readDataWithTimeout:-1 tag:0];
    }
}




@end
