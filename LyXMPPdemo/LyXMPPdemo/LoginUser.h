//
//  LoginUser.h
//  LyXMPPdemo
//
//  Created by 张杰 on 2017/4/4.
//  Copyright © 2017年 张杰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

@interface LoginUser : NSObject
single_interface(LoginUser)

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *hostName;

@property (strong, nonatomic, readonly) NSString *myJIDName;

@end
