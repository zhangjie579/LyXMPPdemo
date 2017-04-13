//
//  LyTabBarViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/10.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyTabBarViewController.h"
#import "LyFriendViewController.h"
#import "LyAddViewController.h"
#import "VCardViewController.h"
#import "LyMessageViewController.h"

@interface LyTabBarViewController ()

@end

@implementation LyTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UITabBar appearance].backgroundColor = [UIColor greenColor];
//    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    LyFriendViewController *homeVC = [[LyFriendViewController alloc] init];
    [self addImage:@"tabbar_home" andSelectImage:@"tabbar_home" viewController:homeVC title:@"好友"];
    
    LyAddViewController *contactVC = [[LyAddViewController alloc]init];
//    LyMessageViewController *contactVC = [[LyMessageViewController alloc] init];
    [self addImage:@"tabbar_message_center" andSelectImage:@"tabbar_message_center" viewController:contactVC title:@"添加"];
    
    VCardViewController *chatVC = [[VCardViewController alloc]init];
    [self addImage:@"tabbar_profile" andSelectImage:@"tabbar_profile" viewController:chatVC title:@"名片"];
}

- (void)addImage:(NSString *)strImge andSelectImage:(NSString *)strSelectImage viewController:(UIViewController *)viewController title:(NSString *)title
{
    viewController.tabBarItem.image = [[UIImage imageNamed:strImge]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController.tabBarItem.selectedImage = [[UIImage imageNamed:strSelectImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController.tabBarItem.title = title;
    [viewController.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]} forState:UIControlStateNormal];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self addChildViewController:nav];
}


@end
