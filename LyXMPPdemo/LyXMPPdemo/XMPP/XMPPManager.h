//
//  XMPPManager.h
//  XmppBlog
//
//  Created by TongLi on 16/3/19.
//  Copyright © 2016年 lanouhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

//枚举，用于区别登陆还是注册
//用ConnectToServerPurpose类型 去代替 NSInteger类型
typedef NS_ENUM(NSInteger , ConnectToServerPurpose) {
    //枚举值
    ConnectToServerPurposeLogin ,
    ConnectToServerPurposeRegister
};

typedef void(^LoginResult)(NSString *loginResult);
typedef void(^RegisterResult)(NSString *RegisterResult);
typedef void(^Refresh)();


@interface XMPPManager : NSObject<XMPPStreamDelegate,XMPPRosterDelegate>
@property (nonatomic,copy)LoginResult loginResult;
@property (nonatomic,copy)RegisterResult registerResult;

@property (nonatomic,strong)NSString *password;
//将枚举设成属性
@property (nonatomic,assign)ConnectToServerPurpose connectToServerPurpose;

//通信通道,用于数据传输，要引入XMPPFramework.h头文件
@property (nonatomic,strong)XMPPStream *xmppStream;
//花名册，用于获取好友
@property (nonatomic,strong)XMPPRoster *xmppRoster;

//好友列表数组
@property (nonatomic,strong)NSMutableArray *friendArr;
//刷新列表block
@property (nonatomic,copy)Refresh refresh;


//信息归档对象
@property (nonatomic,strong)XMPPMessageArchiving *xmppMessageArchiving;
//数据管理器（coredata）
@property (nonatomic,strong)NSManagedObjectContext *context;

//单例
+ (id)shareInstance;


//登录
- (void)loginWithUserID:(NSString *)userID withPassword:(NSString *)password withLoginResult:(LoginResult)loginResult;

//注册
- (void)registerWithUserID:(NSString *)userID withPassword:(NSString *)password withRegisterResult:(RegisterResult )registerResult;

- (void)addFriendActionWithFriendName:(NSString *)friendName;

@end
