//
//  DWQPayManager.h
//  DWQPayManager
//
//  Created by 杜文全 on 15/6/16.
//  Copyright © 2015年 com.sdzw.duwenquan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  此处必须保证在Info.plist 中的 URL Types 的 Identifier 对应一致
 */
#define DWQWECHATURLNAME @"weixin"
#define DWQALIPAYURLNAME @"zhifubao"

#define DWQPAYMANAGER [DWQPayManager shareManager]
/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  回调状态码
 */
typedef NS_ENUM(NSInteger,DWQErrCode){
    DWQErrCodeSuccess,// 成功
    DWQErrCodeFailure,// 失败
    DWQErrCodeCancel// 取消
};

typedef void(^DWQCompleteCallBack)(DWQErrCode errCode,NSString *errStr);
@interface DWQPayManager : NSObject
/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  单例管理
 */
+ (instancetype)shareManager;
/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  处理跳转url，回到应用，需要在delegate中实现
 */
- (BOOL)dwq_handleUrl:(NSURL *)url;
/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  注册App，需要在 didFinishLaunchingWithOptions 中调用
 */
- (void)dwq_registerApp;

/**
 *  @author DevelopmentEngineer-DWQ
 *
 *  发起支付
 *
 * @param orderMessage 传入订单信息,如果是字符串，则对应是跳转支付宝支付；如果传入PayReq 对象，这跳转微信支付,注意，不能传入空字符串或者nil
 * @param callBack     回调，有返回状态信息
 */
- (void)dwq_payWithOrderMessage:(id)orderMessage callBack:(DWQCompleteCallBack)callBack;
@end
