//
//  BaseViewController.h
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/10.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LyXMPPManager.h"

@interface BaseViewController : UIViewController

@property(nonatomic,strong)LyXMPPManager *manager;

@end
