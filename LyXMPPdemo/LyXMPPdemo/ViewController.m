//
//  ViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/2.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "ViewController.h"
#import "LyXMPPManager.h"
#import "LoginUser.h"
#import "XMPPRoom.h"
#import "LyTabBarViewController.h"

@interface ViewController ()<LyXMPPManagerDelegate>

@property(nonatomic,strong)LyXMPPManager *manager;
@property(nonatomic,strong)XMPPRoom *xmppRoom;

@property(nonatomic,strong)UIButton *btn_card;
@property(nonatomic,strong)UIButton *btn_friend;
@property(nonatomic,strong)UIButton *btn_add;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.btn_add];
    
    [self login:@"123" password:@"eyed123456"];
    
    //连接到服务器
    [self.manager connectWithCompletion:^{
        
    } failed:^{
        
    }];
    
}

- (void)btnClick:(UIButton *)btn
{
    [self.navigationController pushViewController:[[LyTabBarViewController alloc] init] animated:YES];
}

- (void)lyXMPPManagerIsReceive:(BOOL)isReceive
{
    LyXMPPCard *card = [self.manager setupvCard];
    
    NSLog(@"%@",card);
}

//登录
- (void)login:(NSString *)userName password:(NSString *)password
{
    LoginUser *log = [LoginUser sharedLoginUser];
    log.userName = userName;
    log.password = password;
    log.hostName = @"192.168.1.1";
}

- (LyXMPPManager *)manager
{
    if (!_manager) {
        _manager = [LyXMPPManager shareManager];
        _manager.delegate = self;
    }
    return _manager;
}

- (UIButton *)btn_add
{
    if (!_btn_add) {
        _btn_add = [[UIButton alloc] init];
        _btn_add.backgroundColor = [UIColor redColor];
        [_btn_add setTitle:@"主页" forState:UIControlStateNormal];
        _btn_add.tag = 1;
        [_btn_add addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        _btn_add.frame = CGRectMake(100, 100, 100, 100);
    }
    return _btn_add;
}

//- (UIButton *)btn_
//{
//    if (!_btn_add) {
//        _btn_add = [[UIButton alloc] init];
//        _btn_add.backgroundColor = [UIColor redColor];
//        [_btn_add setTitle:@"添加好友" forState:UIControlStateNormal];
//        _btn_add.tag = 1;
//        [_btn_add addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _btn_add;
//}
//
//- (UIButton *)btn_add
//{
//    if (!_btn_add) {
//        _btn_add = [[UIButton alloc] init];
//        _btn_add.backgroundColor = [UIColor redColor];
//        [_btn_add setTitle:@"添加好友" forState:UIControlStateNormal];
//        _btn_add.tag = 1;
//        [_btn_add addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _btn_add;
//}

@end
