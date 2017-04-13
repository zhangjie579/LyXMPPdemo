//
//  XMPPManager.m
//  XmppBlog
//
//  Created by TongLi on 16/3/19.
//  Copyright © 2016年 lanouhn. All rights reserved.
//

#import "XMPPManager.h"

@implementation XMPPManager
+ (id)shareInstance {
    static XMPPManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XMPPManager alloc] init];
    });
    return manager;
}

//懒加载好友列表
- (NSMutableArray *)friendArr {
    if (_friendArr == nil) {
        self.friendArr = [NSMutableArray array];
    }
    return _friendArr;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //初始化通信通道
        self.xmppStream = [[XMPPStream alloc]init];
        //给通信通道设置服务器IP地址
        self.xmppStream.hostName = kHostName;
        //给通信通道设置端口
        self.xmppStream.hostPort = kHostPort;
        //给通信通道设置代理
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        //---------------------------------
        //创建花名册数据存储对象
        XMPPRosterCoreDataStorage *xmppRosterStorage = [XMPPRosterCoreDataStorage sharedInstance];
        //创建花名册并指定了存储对象
        self.xmppRoster = [[XMPPRoster alloc]initWithRosterStorage:xmppRosterStorage dispatchQueue:dispatch_get_main_queue()];
        //激活通信通道
        [self.xmppRoster activate:self.xmppStream];
        //添加代理
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        //--------------------------------
        //单例，信息归档存储对象
        XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage= [XMPPMessageArchivingCoreDataStorage sharedInstance];
        //创建信息归档对象
        self.xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:xmppMessageArchivingCoreDataStorage dispatchQueue:dispatch_get_main_queue()];
        //激活通信通道
        [self.xmppMessageArchiving activate:self.xmppStream];
        
        //创建数据管理器
        self.context = xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;


    }
    return self;
}

#pragma mark - 连接服务器 -
//与服务器链接是一个长连接
- (void)connectToServerWithUserID:(NSString *)userID{
    //创建一个JID对象。每个JID对象代表的就是一个封装好的用户
    XMPPJID *jidItem = [XMPPJID jidWithUser:userID domain:kDomin resource:kResource];
    //设置通信通道的JID
    self.xmppStream.myJID = jidItem;
    
    //如果通信通道正在连接或者已经连接
    if ([self.xmppStream isConnecting] || [self.xmppStream isConnected]) {
        //1.发送下线状态
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
        [self.xmppStream sendElement:presence];
        //2.断开连接
        [self.xmppStream disconnect];
    }
    
    //向服务器发送请求。连接成功会走代理方法
    NSError *error = nil;
    [self.xmppStream connectWithTimeout:-1 error:&error];
    if (error != nil) {
        NSLog(@"连接错误");
    }
}

#pragma mark - xmppStream的代理方法 -
//连接成功
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSLog(@"连接成功");
    if (self.connectToServerPurpose == ConnectToServerPurposeLogin) {
        //连接成功。就可以进行登录操作了，验证账号和密码是否匹配
        [self.xmppStream authenticateWithPassword:self.password error:nil];
    }
    if (self.connectToServerPurpose == ConnectToServerPurposeRegister) {
        //连接成功。就可以进行注册操作了，
        [self.xmppStream registerWithPassword:self.password error:nil];
    }
}

//连接超时
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender {
    NSLog(@"连接超时");
}

#pragma mark - 验证的代理方法 -
//已经验证
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    NSLog(@"验证成功");
    //发送一个上线状态
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
    [self.xmppStream sendElement:presence];
    self.loginResult(@"loginSuccess");

}
//验证失败
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    NSLog(@"验证失败");
    self.loginResult(@"loginFail");

}
#pragma mark - 注册结果的代理方法 -
//注册成功了
- (void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"注册成功");

    self.registerResult(@"registerSuccess");
}

//注册失败了
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    NSLog(@"注册失败了");
    self.registerResult(@"registerFail");
}


//登录方法
- (void)loginWithUserID:(NSString *)userID withPassword:(NSString *)password withLoginResult:(LoginResult)loginResult {
    self.connectToServerPurpose = ConnectToServerPurposeLogin;
    
    self.loginResult = loginResult;
    
    self.password = password;
    //连接服务器
    [self connectToServerWithUserID:userID];
    
}
//注册方法
- (void)registerWithUserID:(NSString *)userID withPassword:(NSString *)password withRegisterResult:(RegisterResult )registerResult {
    self.connectToServerPurpose = ConnectToServerPurposeRegister;

    self.password = password;
    self.registerResult = registerResult;
    //连接服务器
    [self connectToServerWithUserID:userID];
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
    self.refresh();
}
//结束检索
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender{
    NSLog(@"结束检索");
}

#pragma mark - 添加好友 -
- (void)addFriendActionWithFriendName:(NSString *)friendName {
    //把账号封装成JID对象
    XMPPJID *addJID = [XMPPJID jidWithUser:friendName domain:kDomin resource:kResource];
    //发送好友请求
    [self.xmppRoster addUser:addJID withNickname:nil];

}
#pragma mark - 接受到好友请求 -
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence{
    NSLog(@"接受到好友请求");
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"添加好友" preferredStyle:UIAlertControllerStyleAlert];
    //添加action
    UIAlertAction *alertAction1 = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //点击了同意之后的方法
        [self.xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
    }];
    UIAlertAction *alertAction2 = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //点击了拒绝之后的方法
        [self.xmppRoster rejectPresenceSubscriptionRequestFrom:presence.from];
    }];
    //将action绑定在UIAlertController上
    [alertC addAction:alertAction1];
    [alertC addAction:alertAction2];
    //显示UIAlertController
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:nil];
}


@end
