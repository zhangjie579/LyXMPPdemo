//
//  LyFriendHeaderView.h
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/11.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LyFriendHeaderView : UITableViewHeaderFooterView

+ (instancetype)headerWithTableView:(UITableView *)tableView;

@property(nonatomic,assign)NSInteger section;
@property(nonatomic,strong)NSNumber *number;

@end
