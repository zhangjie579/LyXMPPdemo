//
//  LyXMPPManager.h
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/2.
//  Copyright © 2017年 张杰. All rights reserved.
//

//用于区别的图片消息还是文本消息,需要与后台沟通
#define LyXMPPImageMessage @"imageMessage:"
#define LyXMPPSoundMessage @"soundMessage:"

typedef enum {
    LyXMPPMessageTypeText,
    LyXMPPMessageTypeImage,
    LyXMPPMessageTypeSound,
}LyXMPPMessageType;

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
@class LyXMPPCard,LyXMPPFriend;

typedef void(^CompletionBlock)();
typedef void(^Refresh)();

@protocol LyXMPPManagerDelegate <NSObject>

@optional
- (void)lyXMPPManagerReceiveFriendRequest:(XMPPPresence *)presence;//获得好友请求
- (void)lyXMPPManagerIsReceive:(BOOL)isReceive;//是否连接上
- (void)lyXMPPManagerChangeFriendData;//好友数据发送改变
@end

@interface LyXMPPManager : NSObject


#pragma mark - XMPP属性及方法
/**
 *  全局的XMPPStream，通信通道,用于数据传输
 */
@property (strong, nonatomic, readonly) XMPPStream *xmppStream;
/**
 *  全局的xmppvCard模块，只读属性
 */
@property (strong, nonatomic, readonly) XMPPvCardTempModule *xmppvCardModule;
/**
 *  全局的XMPPvCardAvatar模块，只读属性
 */
@property (strong, nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
/**
 *  全局的xmppRoster模块，花名册，用于获取好友
 */
@property (strong, nonatomic, readonly) XMPPRoster *xmppRoster;
/**
 *  全局的XMPPRosterCoreDataStorage模块，只读属性
 */
@property (strong, nonatomic, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;

@property(nonatomic,strong)NSFetchedResultsController *resultsContr;//好友

/**
 *  消息存档（归档）模块，只读属性
 */
@property (strong, nonatomic, readonly) XMPPMessageArchiving *xmppMessageArchiving;
@property (strong, nonatomic, readonly) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;

/**
 *  传输文件socket数组
 */
@property (strong, nonatomic) NSMutableArray *socketList;

/**
 *  是否注册用户标示
 */
@property (assign, nonatomic) BOOL isRegisterUser;

@property (weak  , nonatomic) id<LyXMPPManagerDelegate> delegate;

//好友列表数组
@property (nonatomic,strong)NSMutableArray<XMPPJID *> *friendArr;
//刷新列表block
@property (nonatomic,copy)Refresh refresh;

+ (instancetype)shareManager;

/**
 *  连接到服务器
 *
 *  注释：用户信息保存在系统偏好中
 *
 *  @param completion 连接正确的块代码
 *  @param faild      连接错误的块代码
 */
- (void)connectWithCompletion:(CompletionBlock)completion failed:(CompletionBlock)faild;

/**
 *  注销用户登录
 */
- (void)logout;

// 销毁XMPPStream并注销已注册的扩展模块
- (void)teardownStream;

#pragma mark - 好友事件的操作

/* 有数据就是XMPPUserCoreDataStorageObject模型
 _dictFriendModel[@"0"] = @[];//在线
 _dictFriendModel[@"1"] = @[];//离开
 _dictFriendModel[@"2"] = @[];//离线
 _dictFriendModel[@"3"] = @[];//未知状态
 
 //这是用来设置打开关闭分组的
 _dictFriendModel[@"10"] = @0;//关
 _dictFriendModel[@"11"] = @0;
 _dictFriendModel[@"12"] = @0;
 _dictFriendModel[@"13"] = @0;
 */
@property(nonatomic,strong)NSMutableDictionary *dictFriendModel;//XMPPUserCoreDataStorageObject的类型

- (void)getFriendData;

//添加好友
- (void)addFriendWithName:(NSString *)name;

//删除好友
- (void)removeFriend:(XMPPJID *)xmppJID;

/**
 处理添加好友的请求
 
 @param presence XMPPPresence
 @param isAccept 是否接受
 */
- (void)dealWithFriendRequest:(XMPPPresence *)presence isAccept:(BOOL)isAccept;

#pragma mark - 聊天记录，消息

@property(nonatomic,strong)XMPPRoom *xmppRoom;//群聊

////获得与某个好友的聊天记录
//- (void)getRecords:(NSString*)friendsName;
//
///**
// 获得消息列表
// 
// @param friendJid 好友的XMPPJID
// */
//- (void)getChatRecordWithXMPPJID:(XMPPJID *)friendJid;


/**
 发送消息

 @param messageType 消息类型
 @param msg 消息体
 @param to 接收者
 */
- (void)sendMessageType:(LyXMPPMessageType)messageType msg:(id)msg to:(XMPPJID *)to;

#pragma mark - 电子名片处理方法
//获取电子名片
- (LyXMPPCard *)setupvCard;

//更新电子名片,注意:要上传到服务器
- (void)updateCard:(LyXMPPCard *)card;

@end

#pragma mark - 名片
@interface LyXMPPCard : NSObject

@property(nonatomic,strong)UIImage  *icon;//头像
@property(nonatomic,copy  )NSString *usename;//用户名
@property(nonatomic,copy  )NSString *jid;//JID
@property(nonatomic,copy  )NSString *orgName;//公司
@property(nonatomic,copy  )NSString *orgUnits;//部门
@property(nonatomic,copy  )NSString *position;//职务
@property(nonatomic,copy  )NSString *photoNumberText;//电话
@property(nonatomic,copy  )NSString *emailText;//电子邮件

@end


