//
//  BaseViewController.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/10.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()<LyXMPPManagerDelegate>

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (LyXMPPManager *)manager
{
    if (!_manager) {
        _manager = [LyXMPPManager shareManager];
        _manager.delegate = self;
    }
    return _manager;
}

@end
