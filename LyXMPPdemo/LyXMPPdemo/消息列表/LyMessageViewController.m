//
//  LyMessageViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/10.
//  Copyright © 2017年 张杰. All rights reserved.
//  单人聊天页面

#import "LyMessageViewController.h"

@interface LyMessageViewController ()<LyXMPPManagerDelegate,UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,UITextFieldDelegate>

@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSFetchedResultsController *fetchedResultsController;
@property(nonatomic,strong)UITextField *textField;

@end

@implementation LyMessageViewController

#pragma mark - 1 - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.textField];
    
    [self.fetchedResultsController performFetch:NULL];
    [self.tableView reloadData];
    
    NSLog(@"%@",self.fetchedResultsController.fetchedObjects);
}

- (NSFetchedResultsController *)fetchedResultsController {
    // 推荐写法，减少嵌套的层次
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // 先确定需要用到哪个实体
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    
    // 排序
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sort];
    
    // 每一个聊天界面，只关心聊天对象的消息
    request.predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", self.friendJid.bare];
    
    // 从自己写的工具类里的属性中得到上下文
    NSManagedObjectContext *ctx = self.manager.xmppMessageArchivingCoreDataStorage.mainThreadManagedObjectContext;
    
    // 实例化，里面要填上上面的各种参数
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:ctx sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

#pragma mark - 2 - Event Reponse

#pragma mark - 3 - Delegate

#pragma mark -table的数据源

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.fetchedResultsController.fetchedObjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"LyMessageViewController";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    //消息模型
    XMPPMessageArchiving_Message_CoreDataObject *chatMessage = self.fetchedResultsController.fetchedObjects[indexPath.row];
    
    //自己发送的消息
    if ([chatMessage.outgoing boolValue]) {
        //设置消息内容
        cell.textLabel.text =[NSString stringWithFormat:@"me:%@",chatMessage.body];
    }else{//好友发送的消息

     cell.textLabel.text =[NSString stringWithFormat:@"other:%@",chatMessage.body];
    }
    
    //判断是否有图片
    if ([chatMessage.body containsString:LyXMPPImageMessage])
    {
        
        NSString *imgUrl = [chatMessage.body substringFromIndex:LyXMPPImageMessage.length];
        NSLog(@"有图片 %@",imgUrl);
        //自己发送的消息
        if ([chatMessage.outgoing boolValue]) {
            //设置消息内容
            //显示图片
            //        [cell.imageView setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"DefaultProfileHead"]];
        }
        else{//好友发送的消息
            
            //显示图片
            //        [cell.imageView setImageWithURL:[NSURL URLWithString:imgUrl] placeholderImage:[UIImage imageNamed:@"DefaultProfileHead"]];
        }
        
        //消除文字
        cell.textLabel.text = nil;
    }
    else
    {
        //自己发送的消息
        if ([chatMessage.outgoing boolValue]) {
            //设置消息内容
            cell.textLabel.text =[NSString stringWithFormat:@"me:%@",chatMessage.body];
        }else{//好友发送的消息
            
            cell.textLabel.text =[NSString stringWithFormat:@"other:%@",chatMessage.body];
        }
        
        //消除图片
        cell.imageView.image = nil;
    }
    
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//发送消息
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.manager sendMessageType:LyXMPPMessageTypeText msg:textField.text to:self.friendJid];
    self.textField.text = @"";
    return YES;
}

#pragma mark - 4 - Private Methods

#pragma mark - 5 - Getters / Setters

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor whiteColor];
        //        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 50;
        _tableView.sectionHeaderHeight = 30;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

- (UITextField *)textField
{
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.returnKeyType = UIReturnKeySend;
        _textField.enablesReturnKeyAutomatically = YES;
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.backgroundColor = [UIColor whiteColor];
        _textField.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 30, [UIScreen mainScreen].bounds.size.width, 30);
        _textField.delegate = self;
    }
    return _textField;
}

@end
