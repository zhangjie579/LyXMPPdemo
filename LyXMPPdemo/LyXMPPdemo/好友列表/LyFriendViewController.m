//
//  LyFriendViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/10.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyFriendViewController.h"
#import "LyXMPPManager.h"
#import "LyFriendHeaderView.h"
#import "LyMessageViewController.h"

@interface LyFriendViewController ()<LyXMPPManagerDelegate,UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong)UITableView *tableView;

@end

@implementation LyFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    [self.manager getFriendData];
}

- (void)tapClick:(UITapGestureRecognizer *)tap
{
    NSInteger tag = tap.view.tag;
    NSString *key = [NSString stringWithFormat:@"%ld",tag + 10];
    NSNumber *number = self.manager.dictFriendModel[key];
    if ([number isEqual: @0]) {
        number = @1;
    } else {
        number = @0;
    }
    self.manager.dictFriendModel[key] = number;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.manager.dictFriendModel.allKeys.count / 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            NSNumber *number = self.manager.dictFriendModel[@"10"];
            if ([number  isEqual: @0]) {
                return 0;
            } else {
                return [self.manager.dictFriendModel[@"0"] count];
            }
        }
            break;
        case 1:
        {
            NSNumber *number = self.manager.dictFriendModel[@"11"];
            if ([number  isEqual: @0]) {
                return 0;
            } else {
                return [self.manager.dictFriendModel[@"1"] count];
            }
        }
            break;
        case 2:
        {
            NSNumber *number = self.manager.dictFriendModel[@"12"];
            if ([number  isEqual: @0]) {
                return 0;
            } else {
                return [self.manager.dictFriendModel[@"2"] count];
            }
        }
            break;
        case 3:
        {
            NSNumber *number = self.manager.dictFriendModel[@"13"];
            if ([number  isEqual: @0]) {
                return 0;
            } else {
                return [self.manager.dictFriendModel[@"3"] count];
            }
        }
            break;
            
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"FriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
    }
    // Configure the cell...
    //    XMPPUserCoreDataStorageObject *friend = self.friends[indexPath.row];
    //获取对应的好友
    //XMPPUserCoreDataStorageObject *friend = [_resultsContr fetchedObjects][indexPath.row];


    //获取分组后的好友信息
    NSString *key = [NSString stringWithFormat:@"%ld",indexPath.section];
    NSArray *array = self.manager.dictFriendModel[key];
    XMPPUserCoreDataStorageObject *friend = array[indexPath.row];
    cell.textLabel.text = friend.displayName;
    return cell;

//    XMPPUserCoreDataStorageObject *friend = [self.manager.resultsContr objectAtIndexPath:indexPath];
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    LyFriendHeaderView *content = [LyFriendHeaderView headerWithTableView:tableView];
    content.tag = section;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    content.userInteractionEnabled = YES;
    [content.contentView addGestureRecognizer:tap];
    
    NSString *key = [NSString stringWithFormat:@"%ld",section + 10];
    NSNumber *number = self.manager.dictFriendModel[key];
    content.number = number;
    content.section = section;
    return content;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //获取好友
    NSString *key = [NSString stringWithFormat:@"%ld",indexPath.section];
    NSArray *array = self.manager.dictFriendModel[key];
    XMPPUserCoreDataStorageObject *friend = array[indexPath.row];
    
    LyMessageViewController *vc=  [[LyMessageViewController alloc] init];
    vc.friendJid = friend.jid;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

//删除好友
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{

    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //获取好友
        NSString *key = [NSString stringWithFormat:@"%ld",indexPath.section];
        NSArray *array = self.manager.dictFriendModel[key];
        if (array.count != 0)
        {
            XMPPUserCoreDataStorageObject *friend = array[indexPath.row];
            [self.manager removeFriend:friend.jid];
        }
    }

}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor whiteColor];
//        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64 - 49);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 50;
        _tableView.sectionHeaderHeight = 30;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

@end

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    //分组数据
//    return self.manager.resultsContr.sections.count;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    //return [_resultsContr fetchedObjects].count;
//
//    //获取分组的信息
//    id<NSFetchedResultsSectionInfo> sectionInfo = self.manager.resultsContr.sections[section];
//
//    return [sectionInfo numberOfObjects];
//}
//
//
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    //获取分组的信息
//    id<NSFetchedResultsSectionInfo> sectionInfo = self.manager.resultsContr.sections[section];
//
//    //indexTitle就是分组字段(sectionNum)的值
//    NSLog(@"%@",[sectionInfo indexTitle]);
//    NSString *title = nil;
//    int state = [[sectionInfo indexTitle] intValue];
//    switch (state) {
//        case 0:
//            title = @"在线";
//            break;
//        case 1:
//            title = @"离开";
//            break;
//
//        case 2:
//            title  = @"离线";
//            break;
//        default:
//            title = @"未知状态";
//            break;
//    }
//
//    return title;
//}
////
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *ID = @"FriendCell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
//    }
//    // Configure the cell...
//    //    XMPPUserCoreDataStorageObject *friend = self.friends[indexPath.row];
//    //获取对应的好友
//    //XMPPUserCoreDataStorageObject *friend = [_resultsContr fetchedObjects][indexPath.row];
//
//
//    //获取分组后的好友信息
//    XMPPUserCoreDataStorageObject *friend = [self.manager.resultsContr objectAtIndexPath:indexPath];
//    cell.textLabel.text = friend.displayName;
//
//    return cell;
//}
//
////删除好友
//-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
//
//    if (editingStyle == UITableViewCellEditingStyleDelete)
//    {
//        //获取好友
//        XMPPUserCoreDataStorageObject *friend = [self.manager.resultsContr objectAtIndexPath:indexPath];
//
//        [self.manager removeFriend:friend.jid];
//    }
//
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return self.manager.friendArr.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *ID = @"LyFriendViewController";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
//    }
//
//    XMPPJID *model = self.manager.friendArr[indexPath.row];
//    cell.textLabel.text = model.user;
//    cell.detailTextLabel.text = model.domain;
//
//    return cell;
//}

