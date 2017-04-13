//
//  LyFriendHeaderView.m
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/11.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import "LyFriendHeaderView.h"

@interface LyFriendHeaderView ()

@property(nonatomic,strong)UILabel     *label;
@property(nonatomic,strong)UIImageView *image;
@property(nonatomic,strong)UIView      *line;

@end

@implementation LyFriendHeaderView

+ (instancetype)headerWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"LyFriendHeaderView";
    LyFriendHeaderView *views = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ID];
    if (views == nil) {
        views = [[LyFriendHeaderView alloc] initWithReuseIdentifier:ID];
    }
    return views;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.image];
        [self.contentView addSubview:self.label];
        [self.contentView addSubview:self.line];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
        self.userInteractionEnabled = YES;
        [self.contentView addGestureRecognizer:tap];

    }
    return self;
}

- (void)setNumber:(NSNumber *)number
{
    _number = number;
    
    if ([number  isEqual: @0])
    {
        self.image.transform = CGAffineTransformMakeRotation(-M_PI_2);
    } else
    {
        self.image.transform = CGAffineTransformIdentity;
    }
}

- (void)setSection:(NSInteger)section
{
    _section = section;
    
    self.contentView.tag = section;
    
    NSString *title = @"";
    switch (section) {
        case 0:
            title = @"在线";
            break;
        case 1:
            title = @"离开";
            break;
        case 2:
            title  = @"离线";
            break;
        default:
            title = @"未知状态";
            break;
    }
    self.label.text = title;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.image.frame = CGRectMake(10, 5, 15, 15);
    self.label.frame = CGRectMake(35, 5, 120, 20);
    self.line.frame = CGRectMake(10, 29, [UIScreen mainScreen].bounds.size.width - 10, 1);
}

- (UILabel *)label
{
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor redColor];
    }
    return _label;
}

- (UIView *)line
{
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor lightGrayColor];
    }
    return _line;
}

- (UIImageView *)image
{
    if (!_image) {
        _image = [[UIImageView alloc] init];
        _image.image = [UIImage imageNamed:@"navigationbar_arrow_down_os7"];
    }
    return _image;
}

@end
