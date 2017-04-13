//
//  LyXMPPManager.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/2.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyXMPPManager.h"
#import "TURNSocket.h"
#import "XMPPvCardTemp.h"

@interface LyXMPPManager() <XMPPStreamDelegate, XMPPRosterDelegate, TURNSocketDelegate,NSFetchedResultsControllerDelegate,XMPPRoomStorage>
{
    CompletionBlock             _completionBlock;       // 成功的块代码
    CompletionBlock             _faildBlock;            // 失败的块代码
    
    XMPPReconnect               *_xmppReconnect;        // XMPP重新连接XMPPStream
    XMPPvCardCoreDataStorage    *_xmppvCardStorage;     // 电子名片的数据存储模块
    
    XMPPCapabilities            *_xmppCapabilities;     // 实体扩展模块
    XMPPCapabilitiesCoreDataStorage *_xmppCapabilitiesCoreDataStorage; // 数据存储模块
}

// 设置XMPPStream
- (void)setupStream;
// 销毁XMPPStream并注销已注册的扩展模块
- (void)teardownStream;
// 通知服务器器用户上线
- (void)goOnline;
// 通知服务器器用户下线
- (void)goOffline;
// 连接到服务器
- (void)connect;
// 与服务器断开连接
- (void)disconnect;

@end

@implementation LyXMPPManager

+ (instancetype)shareManager
{
    static LyXMPPManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setupStream];
    }
    return self;
}

#pragma mark - XMPP相关方法
// 设置XMPPStream
- (void)setupStream
{
    // 0. 方法被调用时，要求_xmppStream必须为nil，否则通过断言提示程序员，并终止程序运行！
    NSAssert(_xmppStream == nil, @"XMPPStream被多次实例化！");
    
    // 1. 实例化XMPPSteam
    _xmppStream = [[XMPPStream alloc] init];
    
    // 让XMPP在真机运行时支持后台，在模拟器上是不支持后台服务运行的
#if !TARGET_IPHONE_SIMULATOR
    {
        // 允许XMPPStream在真机运行时，支持后台网络通讯！
        [_xmppStream setEnableBackgroundingOnSocket:YES];
    }
#endif
    
    // 2. 扩展模块
    // 2.1 重新连接模块
    _xmppReconnect = [[XMPPReconnect alloc] init];
    //激活
    [_xmppReconnect activate:_xmppStream];
    
    // 2.2 电子名片模块
    _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    //添加电子名片模块
    _xmppvCardModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
    //添加头像模块
    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardModule];
    //激活
    [_xmppvCardModule activate:_xmppStream];
    
    // 2.4 花名册模块
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    // 设置自动接收好友订阅请求
    [_xmppRoster setAutoAcceptKnownPresenceSubscriptionRequests:YES];
    // 自动从服务器更新好友记录，例如：好友自己更改了名片
    [_xmppRoster setAutoFetchRoster:YES];
    
    // 2.5 实体扩展模块
    _xmppCapabilitiesCoreDataStorage = [[XMPPCapabilitiesCoreDataStorage alloc] init];
    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesCoreDataStorage];
    
    // 2.6 消息归档模块
    _xmppMessageArchivingCoreDataStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageArchivingCoreDataStorage];
    
    // 3. 将重新连接模块添加到XMPPStream
    [_xmppReconnect activate:_xmppStream];
    [_xmppvCardModule activate:_xmppStream];
    [_xmppvCardAvatarModule activate:_xmppStream];
    [_xmppRoster activate:_xmppStream];
    [_xmppCapabilities activate:_xmppStream];
    [_xmppMessageArchiving activate:_xmppStream];
    
    // 4. 添加代理
    // 由于所有网络请求都是做基于网络的数据处理，这些数据处理工作与界面UI无关。
    // 因此可以让代理方法在其他线城中运行，从而提高程序的运行性能，避免出现应用程序阻塞的情况
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

// 销毁XMPPStream并注销已注册的扩展模块
- (void)teardownStream
{
    // 1. 删除代理
    [_xmppStream removeDelegate:self];
    [_xmppRoster removeDelegate:self];
    
    // 2. 取消激活在setupStream方法中激活的扩展模块
    [_xmppReconnect deactivate];
    [_xmppvCardModule deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppRoster deactivate];
    [_xmppCapabilities deactivate];
    [_xmppMessageArchiving deactivate];
    
    // 3. 断开XMPPStream的连接
    [_xmppStream disconnect];
    
    // 4. 内存清理
    _xmppStream = nil;
    _xmppReconnect = nil;
    _xmppvCardModule = nil;
    _xmppvCardAvatarModule = nil;
    _xmppvCardStorage = nil;
    _xmppRoster = nil;
    _xmppRosterStorage = nil;
    _xmppCapabilities = nil;
    _xmppCapabilitiesCoreDataStorage = nil;
    _xmppMessageArchiving = nil;
    _xmppMessageArchivingCoreDataStorage = nil;
}

// 通知服务器器用户上线
- (void)goOnline
{
    // 1. 实例化一个”展现“，上线的报告，默认类型为：available
    XMPPPresence *presence = [XMPPPresence presence];
    // 2. 发送Presence给服务器
    // 服务器知道“我”上线后，只需要通知我的好友，而无需通知我，因此，此方法没有回调
    [_xmppStream sendElement:presence];
}

// 通知服务器器用户下线
- (void)goOffline
{
    // 1. 实例化一个”展现“，下线的报告
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    // 2. 发送Presence给服务器，通知服务器客户端下线
    [_xmppStream sendElement:presence];
}

// 连接到服务器
- (void)connect
{
    // 1. 如果XMPPStream当前已经连接，直接返回
    if ([_xmppStream isConnected]) {
        return;
    }
    //    在C语言中if判断真假：非零即真，如果_xmppStream==nil下面这段代码，与上面的代码结果不同。
    //    if (![_xmppStream isDisconnected]) {
    //        return;
    //    }
    
    // 2. 指定用户名、主机（服务器），连接时不需要password
    NSString *hostName = [[LoginUser sharedLoginUser] hostName];
    NSString *userName = [[LoginUser sharedLoginUser] userName];
    
    // 如果没有主机名或用户名（通常第一次运行时会出现），直接显示登录窗口
    if ([self isBlankString:hostName] || [self isBlankString:userName]) {
#warning 没有用户名什么的，直接显示登录窗口
//        [self showStoryboardWithLogonState:NO];
        if ([self.delegate respondsToSelector:@selector(lyXMPPManagerIsReceive:)]) {
            [self.delegate lyXMPPManagerIsReceive:NO];
        }
        return;
    }
    
    // 3. 设置XMPPStream的JID和主机
//    [_xmppStream setMyJID:[XMPPJID jidWithString:userName]];
//    [_xmppStream setHostName:hostName];
    // jid 就是jabberID, 是基于Jabber协议的由用户名生成的唯一ID
    _xmppStream.myJID = [XMPPJID jidWithUser:userName domain:kDomin resource:kResource];
    
    // 4. 开始连接
    NSError *error = nil;
    [_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    
    // 提示：如果没有指定JID和hostName，才会出错，其他都不出错。
    if (error) {
        NSLog(@"连接请求发送出错 - %@", error.localizedDescription);
    } else {
        NSLog(@"连接请求发送成功！");
    }
}

#pragma mark 连接到服务器
- (void)connectWithCompletion:(CompletionBlock)completion failed:(CompletionBlock)faild
{
    // 1. 记录块代码
    _completionBlock = completion;
    _faildBlock = faild;
    
    // 2. 如果已经存在连接，先断开连接，然后再次连接
    if ([_xmppStream isConnected]) {
        [_xmppStream disconnect];
    }
    
    // 3. 连接到服务器
    [self connect];
}

// 与服务器断开连接
- (void)disconnect
{
    // 1. 通知服务器下线
    [self goOffline];
    // 2. XMPPStream断开连接
    [_xmppStream disconnect];
}

- (void)logout
{
    // 1. 通知服务器下线，并断开连接
    [self disconnect];
    
    // 2. 显示用户登录Storyboard
#warning 去登录页面
//    [self showStoryboardWithLogonState:NO];
    if ([self.delegate respondsToSelector:@selector(lyXMPPManagerIsReceive:)]) {
        [self.delegate lyXMPPManagerIsReceive:NO];
    }
}

#pragma mark - 代理方法
#pragma mark 连接完成（如果服务器地址不对，就不会调用此方法）
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"111111连接成功");
    // 从系统偏好读取用户密码
    NSString *password = [[LoginUser sharedLoginUser] password];
    
    if (_isRegisterUser) {
        // 用户注册，发送注册请求
        [_xmppStream registerWithPassword:password error:nil];
    } else {
        // 用户登录，发送身份验证请求
        [_xmppStream authenticateWithPassword:password error:nil];
    }
}

#pragma mark 注册成功
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    _isRegisterUser = NO;
    
    // 注册成功，直接发送验证身份请求，从而触发后续的操作
    [_xmppStream authenticateWithPassword:[LoginUser sharedLoginUser].password error:nil];
}

#pragma mark 注册失败(用户名已经存在)
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    _isRegisterUser = NO;
    if (_faildBlock != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _faildBlock();
        });
    }
}

#pragma mark 身份验证通过
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    if (_completionBlock != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _completionBlock();
        });
    }
    
    // 通知服务器用户上线
    [self goOnline];
    
    // 显示主Storyboard
#warning 显示主页面
//    [self showStoryboardWithLogonState:YES];
    if ([self.delegate respondsToSelector:@selector(lyXMPPManagerIsReceive:)]) {
        [self.delegate lyXMPPManagerIsReceive:YES];
    }
}

#pragma mark 密码错误，身份验证失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    if (_faildBlock != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _faildBlock();
        });
    }
    
    // 显示用户登录Storyboard
#warning 显示用户登录页面
//    [self showStoryboardWithLogonState:NO];
    if ([self.delegate respondsToSelector:@selector(lyXMPPManagerIsReceive:)]) {
        [self.delegate lyXMPPManagerIsReceive:NO];
    }
}

#pragma mark 用户展现变化
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"接收到用户展现数据 - %@", presence);
    
    // 1. 判断接收到的presence类型是否为subscribe
    if ([presence.type isEqualToString:@"subscribe"]) {
        // 2. 取出presence中的from的jid
        XMPPJID *from = [presence from];
        
        // 3. 接受来自from添加好友的订阅请求
        [_xmppRoster acceptPresenceSubscriptionRequestFrom:from andAddToRoster:YES];
    }
}

#pragma mark 判断IQ是否为SI请求
- (BOOL)isSIRequest:(XMPPIQ *)iq
{
    NSXMLElement *si = [iq elementForName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    NSString *uuid = [[si attributeForName:@"id"]stringValue];
    
    if(si &&uuid ){
        return YES;
    }
    
    return NO;
}

#pragma mark 接收请求
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    NSLog(@"接收到请求 - %@", iq);
    
    // 0. 判断IQ是否为SI请求
    if ([self isSIRequest:iq]) {
        TURNSocket *socket = [[TURNSocket alloc] initWithStream:_xmppStream toJID:iq.to];
        
        [_socketList addObject:socket];
        
        [socket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    } else if ([TURNSocket isNewStartTURNRequest:iq]) {
        // 1. 判断iq的类型是否为新的文件传输请求
        // 1) 实例化socket
        TURNSocket *socket = [[TURNSocket alloc] initWithStream:sender incomingTURNRequest:iq];
        
        // 2) 使用一个数组成员记录住所有传输文件使用的socket
        [_socketList addObject:socket];
        
        // 3）添加代理
        [socket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    return YES;
}

#pragma mark 接收消息
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"接收到用户消息 - %@", message);
    
    // 1. 针对图像数据单独处理，取出数据
    NSString *imageStr = [[message elementForName:@"imageData"] stringValue];
    
    if (imageStr) {
        // 2. 解码成图像
        NSData *data = [[NSData alloc] initWithBase64EncodedString:imageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
        
        // 3. 保存图像
        UIImage *image = [UIImage imageWithData:data];
        // 4. 将图像保存到相册
        // 1) target 通常用self
        // 2) 保存完图像调用的方法
        // 3) 上下文信息
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

#pragma mark - 花名册代理方法 -
//开始检索
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender{
    NSLog(@"开始检索了");
    [self.friendArr removeAllObjects];
}

//检索到好友
- (void)xmppRoster:(XMPPRoster *)sender didRecieveRosterItem:(DDXMLElement *)item{
    NSLog(@"检索到好友");
    //  获取节点的属性
    //  subscription:粉，订阅的意思，
    //  both代表，两者互为好友
    //  to代表：自己粉别人，别人未粉你
    //  from代表：别人粉自己，自己未粉别人
    //  我们要展示好友列表，所以说找subscription为both的item
    NSString *subscriptionValue = [[item attributeForName:@"subscription"] stringValue];
    
    //  展示互为好友的信息
    if ([subscriptionValue isEqualToString:@"both"]) {
        NSString *jidStr = [[item attributeForName:@"jid"] stringValue];
        //  封装成XMPPJID
        XMPPJID *friendJID = [XMPPJID jidWithString:jidStr];
        //  如果数组中已经包含了这个好友对象，就不再进行添加了
        if ([self.friendArr containsObject:friendJID]) {
            return;
        }
        //  添加到数据源数组中
        [self.friendArr addObject:friendJID];
    }
    //刷新列表
    if (self.refresh) {
        self.refresh();
    }
}
//结束检索
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender{
    NSLog(@"结束检索");
}

#pragma mark - XMPPRoster代理
//接收到好友请求
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"接收到其他用户的请求 %@", presence);
    
    if ([self.delegate respondsToSelector:@selector(lyXMPPManagerReceiveFriendRequest:)]) {
        [self.delegate lyXMPPManagerReceiveFriendRequest:presence];
    }
    
//    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"添加好友" preferredStyle:UIAlertControllerStyleAlert];
//    //添加action
//    UIAlertAction *alertAction1 = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        //点击了同意之后的方法
//        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
//    }];
//    UIAlertAction *alertAction2 = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        //点击了拒绝之后的方法
//        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:presence.from];
//    }];
//    //将action绑定在UIAlertController上
//    [alertC addAction:alertAction1];
//    [alertC addAction:alertAction2];
//    //显示UIAlertController
//    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
}

#pragma mark - TURNSocket代理
- (void)turnSocket:(TURNSocket *)sender didSucceed:(GCDAsyncSocket *)socket
{
    NSLog(@"成功");
    
    // 保存或者发送文件
    // 写数据方法，向其他客户端发送文件
    //    socket writeData:<#(NSData *)#> withTimeout:<#(NSTimeInterval)#> tag:<#(long)#>
    // 读数据方法，接收来自其他客户端的文件
    //    socket readDataToData:<#(NSData *)#> withTimeout:<#(NSTimeInterval)#> tag:<#(long)#>
    
    // 读写操作完成之后断开网络连接
    [socket disconnectAfterReadingAndWriting];
    
    [_socketList removeObject:sender];
}

- (void)turnSocketDidFail:(TURNSocket *)sender
{
    NSLog(@"失败");
    
    [_socketList removeObject:sender];
}

#pragma mark - 好友的事件操作
//添加好友
- (void)addFriendWithName:(NSString *)name
{
    // 1. 判断输入是否由域名
    NSRange range = [name rangeOfString:@"@"];
    
    if (NSNotFound == range.location) {
        // 2. 如果没有，添加域名合成完整的JID字符串
        // 在name尾部添加域名
        name = [NSString stringWithFormat:@"%@@%@", name, [LoginUser sharedLoginUser].hostName];
    }
    
    // 3. 判断是否与当前用户相同
    if ([name isEqualToString:[LoginUser sharedLoginUser].myJIDName]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"自己不用添加自己！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return;
    }
    
    // 4. 判断是否已经是自己的好友
    // 注释：userExistsWithJID方法仅用于检测指定的JID是否是用户的好友，而不是检测是否是合法的JID账户
    if ([_xmppRosterStorage userExistsWithJID:[XMPPJID jidWithString:name] xmppStream:_xmppStream]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"该用户已经是好友，无需添加！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return;
    }
    
    // 5. 发送添加好友请求
    [_xmppRoster subscribePresenceToUser:[XMPPJID jidWithUser:name domain:kDomin resource:kResource]];
    
    // 6. 提示用户发送成功
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"添加好友请求已发送" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    
    [alert show];
}

/**
 处理添加好友的请求
 
 @param presence XMPPPresence
 @param isAccept 是否接受
 */
- (void)dealWithFriendRequest:(XMPPPresence *)presence isAccept:(BOOL)isAccept
{
    if (isAccept)
    {
        //点击了同意之后的方法
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
    }
    else
    {
        //点击了拒绝之后的方法
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:presence.from];
    }
}

//删除好友
- (void)removeFriend:(XMPPJID *)xmppJID
{
    [self.xmppRoster removeUser:xmppJID];
}

- (void)getFriendData
{
    //从数据库获取好友列表
    //1.拿上下文
    NSManagedObjectContext *rosterContext = self.xmppRosterStorage.mainThreadManagedObjectContext;
    
    //2.创建查询对象
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    //3.设置排序
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors = @[sort];
    
    
    //第一种方法查询数据
    //4.执行请求
    //    NSError *error = nil;
    //    self.friends = [rosterContext executeFetchRequest:request error:&error];
    //   JPLogInfo(@"%@",self.friends);
    //    if (error) {
    //        JPLogInfo(@"%@",error);
    //    }
    //
    //第二种方法查询数据
    //    _resultsContr = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:rosterContext sectionNameKeyPath:nil cacheName:nil];
    
    //sectionNum是在线状态 根据在线状态进行分组查询
    self.resultsContr = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:rosterContext sectionNameKeyPath:@"sectionNum" cacheName:nil];
    
    //执行查询
    NSError *error = nil;
    [self.resultsContr performFetch:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    //设置代理
    self.resultsContr.delegate = self;
    
//    NSArray *mFriends = [_resultsContr fetchedObjects];
//    NSLog(@"%@=",mFriends);
    
    //处理数据
    for (NSInteger i = 0; i < self.resultsContr.sections.count; i++)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = self.resultsContr.sections[i];
        NSString *key = [sectionInfo indexTitle];
        
        if ([key isEqualToString:@"0"] || [key isEqualToString:@"1"] || [key isEqualToString:@"2"])
        {
            self.dictFriendModel[key] = [sectionInfo objects];
        }
        else
        {
            self.dictFriendModel[@"3"] = [sectionInfo objects];
        }
    }
}

#pragma mark NSFetchedResultsController的代理
/**
 *  查询好友的数据改变会调用这个方法(比如,删除好友,添加好友)
 *
 *  @param controller <#controller description#>
 */
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(lyXMPPManagerChangeFriendData)]) {
        [self.delegate lyXMPPManagerChangeFriendData];
    }
}

#pragma mark - 聊天记录，消息

////获得与某个好友的聊天记录
//-(void) getRecords:(NSString*) friendsName
//{
//    
//    //所有账号 和所有人的聊天记录都在同一个数据库内  所以 要写查询条件
//    NSManagedObjectContext *context = self.xmppRosterStorage.mainThreadManagedObjectContext;
//    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
//    NSString *userinfo = [NSString stringWithFormat:@"%@@%@",[LoginUser sharedLoginUser].userName,kDomin];
//    NSString *friendinfo = [NSString stringWithFormat:@"%@@%@",friendsName,kDomin];
//    NSPredicate *predicate =
//    [NSPredicate predicateWithFormat:@" streamBareJidStr = %@ and bareJidStr = %@",userinfo,friendinfo];
//    request.predicate = predicate;
//    
//    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
//    request.sortDescriptors = @[sort];
//    
//    self.resultsContr = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
//    self.resultsContr.delegate = self;
//    NSError *error;
//    [self.resultsContr performFetch:&error];
//    //   返回的值类型 XMPPMessageArchiving_Message_CoreDataObject
////    return self.resultsContr.fetchedObjects;
//}
//
///**
// 获得消息列表
//
// @param friendJid 好友的XMPPJID
// */
//- (void)getChatRecordWithXMPPJID:(XMPPJID *)friendJid
//{
//    //1.上下文
//    NSManagedObjectContext *context = self.xmppRosterStorage.mainThreadManagedObjectContext;
//    
//    //2.查询请求(查询哪张表)
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
//    
//    //3.设置排序(时间升序)
//    NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
//    
//    request.sortDescriptors = @[timeSort];
//    
//    //4.过滤条件(当前登录用户jid , 好友jid)
//    XMPPJID *myJid = self.xmppStream.myJID;
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@ AND streamBareJidStr = %@",friendJid.bare,myJid.bare];    
//    
//    request.predicate = predicate;
//    
////    [context executeFetchRequest:request error:nil];
//    self.messageList = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
//    
//    //设置代理
//    self.messageList.delegate = self;
//    
//    //执行请求
//    NSError *error = nil;
//    
//    [self.messageList performFetch:&error];
//}

//发送消息
- (void)sendMessageType:(LyXMPPMessageType)messageType msg:(id)msg to:(XMPPJID *)to
{
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:to];
    NSString *body = @"";
    if (messageType == LyXMPPMessageTypeImage)//图片消息
    {
        //1.上传图片到服务器 -> 获得url
        NSString *imgUrl = @"";
        //2.发送消息
        body = [NSString stringWithFormat:@"%@%@",LyXMPPImageMessage,imgUrl];
    }
    else if (messageType == LyXMPPMessageTypeSound)
    {
        
    }
    else if (messageType == LyXMPPMessageTypeText)
    {
        body = msg;
    }
    
    [message addBody:body];
    //所有跟根据通信的话,用XMPPStream
    //发送消息
    [self.xmppStream sendElement:message];
}


#pragma mark -------------   群聊    ------------

/**
 创建群聊

 @param roomJid 群ID
 @param roomName 群名
 */
- (void)creatRoom:(NSString *)roomJid roomName:(NSString *)roomName
{
    /* 注意:
     第一个参数，是XMPPRoomCoreDataStorage类型，他是为这个房间分配一个coredata的数据库
     第二个参数则是Room的JID这个需要自己分配，不能跟服务器已经有的JID重复
     第三个参数则是房间所在队列，使用串行，不要再主线
     */
    XMPPRoomCoreDataStorage *storage = [[XMPPRoomCoreDataStorage alloc] init];
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:storage jid:[XMPPJID jidWithString:roomJid] dispatchQueue:dispatch_queue_create("com.lyDemo.RoomQueue",DISPATCH_QUEUE_SERIAL)];
    [self.xmppRoom activate:self.xmppStream];
    [self.xmppRoom joinRoomUsingNickname:roomName history:nil];
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppRoom fetchConfigurationForm];
    //房间的配置
}


#pragma mark - 电子名片处理方法
#pragma mark - 设置电子名片
- (LyXMPPCard *)setupvCard
{
    // 1. 获取当前账号的电子名片
    XMPPvCardTemp *myCard = [_xmppvCardModule myvCardTemp];
    
    // 2. 判断当前账号是否有电子名片
    if (myCard == nil) {
        // 1. 新建电子名片
        myCard = [XMPPvCardTemp vCardTemp];
        // 2. 设置昵称
        myCard.nickname = [[LoginUser sharedLoginUser] userName];
    }
    
    // 设置jid
    if (myCard.jid == nil) {
        myCard.jid = [XMPPJID jidWithString:[LoginUser sharedLoginUser].myJIDName];
    }
    
    // 更新或保存电子名片
    [_xmppvCardModule updateMyvCardTemp:myCard];
    
    LyXMPPCard *card = [[LyXMPPCard alloc] init];
    // 使用myCard中的信息设置界面UI显示
    // 1) 照片
    NSData *photoData = [_xmppvCardAvatarModule photoDataForJID:myCard.jid];
    if (photoData) {
//        _headImageView.image = [UIImage imageWithData:photoData];
        card.icon = [UIImage imageWithData:photoData];
    }
    // 2) 用户名
    card.usename = myCard.nickname;
    // 3) JID
    card.jid = [myCard.jid full];
    // 4) 公司
    card.orgName = myCard.orgName;
    // 5) 部门
    if (myCard.orgUnits.count != 0) {
        card.orgUnits = myCard.orgUnits[0];
    }
    // 6) 职务
    card.position = myCard.title;
    // 7) 电话
    card.photoNumberText = myCard.note;
    // 8) 电子邮件
    card.emailText = myCard.mailer;
    
    return card;
}

#pragma mark - 更新电子名片
// 注释：此处代码有点偷懒，不管字段是否更改，都一次性保存所有字段内容
- (void)updateCard:(LyXMPPCard *)card
{
    // 1. 获取电子名片
    XMPPvCardTemp *myCard = [_xmppvCardModule myvCardTemp];
    
    // 2. 设置名片内容
    if (card.icon != nil) {
        myCard.photo = UIImagePNGRepresentation(card.icon);
    }
    myCard.nickname = [card.usename trimString];
    myCard.orgName = [card.orgName trimString];
    if (card.orgUnits != nil && ![card.orgUnits isEqualToString:@""]) {
        myCard.orgUnits = @[[card.orgUnits trimString]];
    }
    myCard.title = [card.position trimString];
    myCard.note = [card.photoNumberText trimString];
    myCard.mailer = [card.emailText trimString];
    
    // 3. 保存电子名片
    // 先存储到本地,接着上传到服务器
    [_xmppvCardModule updateMyvCardTemp:myCard];
}

#pragma mark - get

- (NSMutableArray *)socketList
{
    if (!_socketList) {
        _socketList = [[NSMutableArray alloc] init];
    }
    return _socketList;
}

- (NSMutableArray<XMPPJID *> *)friendArr
{
    if (!_friendArr) {
        _friendArr = [[NSMutableArray alloc] init];
    }
    return _friendArr;
}

- (NSMutableDictionary *)dictFriendModel
{
    if (!_dictFriendModel) {
        _dictFriendModel = [[NSMutableDictionary alloc] init];
        _dictFriendModel[@"0"] = @[];//在线
        _dictFriendModel[@"1"] = @[];//离开
        _dictFriendModel[@"2"] = @[];//离线
        _dictFriendModel[@"3"] = @[];//未知状态
        
        _dictFriendModel[@"10"] = @0;//关
        _dictFriendModel[@"11"] = @0;
        _dictFriendModel[@"12"] = @0;
        _dictFriendModel[@"13"] = @0;
    }
    return _dictFriendModel;
}

#pragma mark - tool

//判断某字符串是否为空
- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}


@end


#pragma mark - LyXMPPCard
@implementation LyXMPPCard


@end

