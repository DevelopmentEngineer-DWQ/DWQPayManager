//
//  DWQPayManager.m
//  DWQPayManager
//
//  Created by 杜文全 on 15/6/16.
//  Copyright © 2015年 com.sdzw.duwenquan. All rights reserved.
//

#import "DWQPayManager.h"
// 回调url地址为空
#define DWQTIP_CALLBACKURL @"url地址不能为空！"
// 订单信息为空字符串或者nil
#define DWQTIP_ORDERMESSAGE @"订单信息不能为空！"
// 没添加 URL Types
#define DWQTIP_URLTYPE @"请先在Info.plist 添加 URL Type"
// 添加了 URL Types 但信息不全
#define DWQTIP_URLTYPE_SCHEME(name) [NSString stringWithFormat:@"请先在Info.plist 的 URL Type 添加 %@ 对应的 URL Scheme",name]
@interface DWQPayManager ()<WXApiDelegate>
// 缓存回调
@property (nonatomic,copy)DWQCompleteCallBack callBack;
// 缓存appScheme
@property (nonatomic,strong)NSMutableDictionary *appSchemeDict;
@end

@implementation DWQPayManager
+ (instancetype)shareManager{
    static DWQPayManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (BOOL)dwq_handleUrl:(NSURL *)url{
    
    NSAssert(url, DWQTIP_CALLBACKURL);
    if ([url.host isEqualToString:@"pay"]) {// 微信
        return [WXApi handleOpenURL:url delegate:self];
    }
    else if ([url.host isEqualToString:@"safepay"]) {// 支付宝
        // 支付跳转支付宝钱包进行支付，处理支付结果(在app被杀模式下，通过这个方法获取支付结果）
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSString *resultStatus = resultDic[@"resultStatus"];
            NSString *errStr = resultDic[@"memo"];
            DWQErrCode errorCode = DWQErrCodeSuccess;
            switch (resultStatus.integerValue) {
                case 9000:// 成功
                    errorCode = DWQErrCodeSuccess;
                    break;
                case 6001:// 取消
                    errorCode = DWQErrCodeCancel;
                    break;
                default:
                    errorCode = DWQErrCodeFailure;
                    break;
            }
            if ([DWQPayManager shareManager].callBack) {
                [DWQPayManager shareManager].callBack(errorCode,errStr);
            }
        }];
        
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
        return YES;
    }
    else{
        return NO;
    }
}

- (void)dwq_registerApp{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *urlTypes = dict[@"CFBundleURLTypes"];
    NSAssert(urlTypes, DWQTIP_URLTYPE);
    for (NSDictionary *urlTypeDict in urlTypes) {
        NSString *urlName = urlTypeDict[@"CFBundleURLName"];
        NSArray *urlSchemes = urlTypeDict[@"CFBundleURLSchemes"];
        NSAssert(urlSchemes.count, DWQTIP_URLTYPE_SCHEME(urlName));
        // 一般对应只有一个
        NSString *urlScheme = urlSchemes.lastObject;
        if ([urlName isEqualToString:DWQWECHATURLNAME]) {
            [self.appSchemeDict setValue:urlScheme forKey:DWQWECHATURLNAME];
            // 注册微信
            [WXApi registerApp:urlScheme];
        }
        else if ([urlName isEqualToString:DWQALIPAYURLNAME]){
            // 保存支付宝scheme，以便发起支付使用
            [self.appSchemeDict setValue:urlScheme forKey:DWQALIPAYURLNAME];
        }
        else{
            
        }
    }
}

- (void)dwq_payWithOrderMessage:(id)orderMessage callBack:(DWQCompleteCallBack)callBack{
    NSAssert(orderMessage, DWQTIP_ORDERMESSAGE);
    // 缓存block
    self.callBack = callBack;
    // 发起支付
    if ([orderMessage isKindOfClass:[PayReq class]]) {
        // 微信
        NSAssert(self.appSchemeDict[DWQWECHATURLNAME], DWQTIP_URLTYPE_SCHEME(DWQWECHATURLNAME));
        
        [WXApi sendReq:(PayReq *)orderMessage];
    }
    else if ([orderMessage isKindOfClass:[NSString class]]){
        // 支付宝
        NSAssert(![orderMessage isEqualToString:@""], DWQTIP_ORDERMESSAGE);
        NSAssert(self.appSchemeDict[DWQALIPAYURLNAME], DWQTIP_URLTYPE_SCHEME(DWQALIPAYURLNAME));
        [[AlipaySDK defaultService] payOrder:(NSString *)orderMessage fromScheme:self.appSchemeDict[DWQALIPAYURLNAME] callback:^(NSDictionary *resultDic){
            NSString *resultStatus = resultDic[@"resultStatus"];
            NSString *errStr = resultDic[@"memo"];
            DWQErrCode errorCode = DWQErrCodeSuccess;
            switch (resultStatus.integerValue) {
                case 9000:// 成功
                    errorCode = DWQErrCodeSuccess;
                    break;
                case 6001:// 取消
                    errorCode = DWQErrCodeCancel;
                    break;
                default:
                    errorCode = DWQErrCodeFailure;
                    break;
            }
            if ([DWQPayManager shareManager].callBack) {
                [DWQPayManager shareManager].callBack(errorCode,errStr);
            }
        }];
    }
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    // 判断支付类型
    if([resp isKindOfClass:[PayResp class]]){
        //支付回调
        DWQErrCode errorCode = DWQErrCodeSuccess;
        NSString *errStr = resp.errStr;
        switch (resp.errCode) {
            case 0:
                errorCode = DWQErrCodeSuccess;
                errStr = @"订单支付成功";
                break;
            case -1:
                errorCode = DWQErrCodeFailure;
                errStr = resp.errStr;
                break;
            case -2:
                errorCode = DWQErrCodeCancel;
                errStr = @"用户中途取消";
                break;
            default:
                errorCode = DWQErrCodeFailure;
                errStr = resp.errStr;
                break;
        }
        if (self.callBack) {
            self.callBack(errorCode,errStr);
        }
    }
}

#pragma mark -- Setter & Getter

- (NSMutableDictionary *)appSchemeDict{
    if (_appSchemeDict == nil) {
        _appSchemeDict = [NSMutableDictionary dictionary];
    }
    return _appSchemeDict;
}

@end
