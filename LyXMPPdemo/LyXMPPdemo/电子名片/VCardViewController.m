//
//  VCardViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/6.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "VCardViewController.h"
// 电子名片
#import "XMPPvCardCoreDataStorage.h"
#import"XMPPvCardTempModule.h"
// 头像模块
#import "XMPPvCardAvatarModule.h"

@interface VCardViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UIButton *btn;
@property(nonatomic,strong)UITableView *tableView;
@end

@implementation VCardViewController

#pragma mark - 1 - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"电子名片";
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.tableView];
}

#pragma mark - 2 - Event Reponse

- (void)btnClick
{
    LyXMPPCard *card = [[LyXMPPCard alloc] init];
    card.usename = @"ly";
    card.icon = [UIImage imageNamed:@"icon"];
    card.orgName = @"orgName";
    card.position = @"ios";
    card.photoNumberText = @"12345678";
    card.emailText = @"123456@qq.com";
    [self.manager updateCard:card];
    
    LyXMPPCard *new = [self.manager setupvCard];
    
    NSLog(@"%@",new);
}

#pragma mark - 3 - Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"LyFriendViewController";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
    }
    
    LyXMPPCard *card = [self.manager setupvCard];
    
    switch (indexPath.row) {
        case 0:
        {
            cell.textLabel.text = @"用户名";
            cell.detailTextLabel.text = card.usename;
        }
            break;
        case 1:
        {
            cell.textLabel.text = @"JID";
            cell.detailTextLabel.text = card.jid;
        }
            break;
        case 2:
        {
            cell.textLabel.text = @"公司";
            cell.detailTextLabel.text = card.orgName;
        }
            break;
        case 3:
        {
            cell.textLabel.text = @"部门";
            cell.detailTextLabel.text = card.orgUnits;
        }
            break;
        case 4:
        {
            cell.textLabel.text = @"职务";
            cell.detailTextLabel.text = card.position;
        }
            break;
        case 5:
        {
            cell.textLabel.text = @"电话";
            cell.detailTextLabel.text = card.photoNumberText;
        }
            break;
        case 6:
        {
            cell.textLabel.text = @"邮箱";
            cell.detailTextLabel.text = card.emailText;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 4 - Private Methods

#pragma mark - 5 - Getters / Setters

- (UIButton *)btn
{
    if (!_btn) {
        _btn = [[UIButton alloc] init];
        _btn.backgroundColor = [UIColor yellowColor];
        [_btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
        _btn.frame = CGRectMake(100, 100, 100, 100);
    }
    return _btn;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor whiteColor];
        //        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 50;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

@end
