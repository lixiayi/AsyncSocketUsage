//
//  ChatHandler.h
//  ASyncSockdDemo
//
//  Created by stoicer on 2022/9/26.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"



/**
 
 1. 普通网络监听
  
  由于即时通讯对于网络状态的判断需要较为精确 ，原生的Reachability实际上在很多时候判断并不可靠 。
  主要体现在当网络较差时，程序可能会出现连接上网络 ， 但并未实际上能够进行数据传输 。
  开始尝试着用Reachability加上一个普通的网络请求来双重判断实现更加精确的网络监听 ， 但是实际上是不可行的 。
  如果使用异步请求依然判断不精确 ， 若是同步请求 ， 对性能的消耗会很大 。
  最终采取的解决办法 ， 使用RealReachability ，对网络监听同时 ，PING服务器地址或者百度 ，网络监听问题基本上得以解决
 
 用AFNetwroking的方法
 networkStatusaddDelegate
 
 
 2. TCP连接状态监听：
  
  TCP的连接状态监听主要使用服务器和客户端互相发送心跳 ，彼此验证对方的连接状态 。
  规则可以自己定义 ， 当前使用的规则是 ，当客户端连接上服务器端口后 ，且成功建立SSL验证后 ，向服务器发送一个登陆的消息(login)。
  当收到服务器的登陆成功回执（loginReceipt)开启心跳定时器 ，每一秒钟向服务器发送一次心跳 ，心跳的内容以安卓端/iOS端/服务端最终协商后为准 。
  当服务端收到客户端心跳时，也给服务端发送一次心跳 。正常接收到对方的心跳时，当前连接状态为已连接状态 ，当服务端或者客户端超过3次（自定义）没有收到对方的心跳时，判断连接状态为未连接。
 
 
 3、关于消息分发 - 注册多个代理
  
  全局咱们设定了一个ChatHandler单例，用于处理TCP的相关逻辑 。那么当TCP推送过来消息时，我该将这些消息发给谁？谁注册成为我的代理，我就发给谁。
  ChatHandler单例为全局的，并且生命周期为整个app运行期间不会销毁。在ChatHandler中引用一个数组 ，该数组中存放所有注册成为需要收取消息的代理，当每来一条消息时，遍历该数组，并向所有的代理推送该条消息.
 
 
 4、关于重连机制
 什么时候触发重连 ?   1 . 当3次没有收到服务器的心跳时  , 默认进行重连 .  2 . 当检测到socket断开连接时 , 默认进行3次重连  3 . 当网络状态良好,但socket处于断开状态时,进行重连
 
 */
NS_ASSUME_NONNULL_BEGIN

@protocol ChatHanderDelegeate <NSObject>

@required
- (void)recvMsg:(id)data;

@optional
- (void)sendMsg:(id)data;

@end

@interface ChatHandler : NSObject

/** 发送心跳的定时器 */
@property (nonatomic, strong)  dispatch_source_t heartBeatTimer;

/** 发送心跳次数 */
@property (nonatomic, assign) int heartBeatCount;

/** socket 重连次数*/
@property (nonatomic, assign) int retryCount;


/** client */
@property (nonatomic, strong) GCDAsyncSocket *client;

/** 是否已连接  */
@property (nonatomic, assign) BOOL isConnected;

/** 代理数组 */
@property (nonatomic, strong) NSMutableArray *delegateArray;

///单例
+ (instancetype )shareManager;


/// 添加代理
- (void)addChatDelegate:(id<ChatHanderDelegeate>)delegate;



/// 移除代理
- (void)removeChatDelegate:(id<ChatHanderDelegeate>)delegate;


/// 发送消息
/// @param model
- (void)sendMessageWitchModel:(id)model;

@end

NS_ASSUME_NONNULL_END
