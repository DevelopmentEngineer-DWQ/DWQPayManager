# DWQPayManager
针对微信支付/支付宝支付的封装，方便使用。
#一、引述

- 1、上一篇文章我们讲的是[规格属性选择](http://www.jianshu.com/p/a8433e2227ce)；通常情况下，在电商平台购物的下一步操作就是立即购买或者添加到购物车了，今天，我们先讲立即购买，那么，肯定涉及到的就是支付。如今这个移动支付火爆的年代，如果你的APP不能够实现移动支付，那是不是已经被时代潮流远远的甩在了后面。

- 2、移动支付常用的是支付宝和微信，统一管理岂不是很方便！所以本篇主要讲解统一管理的支付工具封装说实话，银联支付比较鸡肋，用的人特别少，所以就没再将其封装。

#二、支付宝和微信API分析
- 作者在此对比了支付宝和微信的支付API，分析一下它们接口的异同点：[支付宝官方文档](https://doc.open.alipay.com/doc2/detail.htm?treeId=204&articleId=105302&docType=1)     [微信官方文档](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_5)
  -  （1）支付宝是不需要在`didFinishLaunchingWithOptions` 中注册，而微信则需要调用`registerApp` 注册

  -  （2）支付宝有web回调，而微信没有，当然这个对整合没影响（因为最终都要统一成一个回调）

  -  （3）支付宝发起支付是传入订单信息（字符串类型），而微信则传入一个`BaseReq` 类或者其子类（支付的是`PayReq` 类），此时根据这点差异性可以通过传入id 类型，然后内部做判断，进行跳转不同的支付方式，来看看他们的接口

  >**支付宝发起支付**

  ```
  /**
   *  支付接口
   *
   *  @param orderStr       订单信息
   *  @param schemeStr      调用支付的app注册在info.plist中的scheme
   *  @param completionBlock 支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
   */
  - (void)payOrder:(NSString *)orderStr
        fromScheme:(NSString *)schemeStr
          callback:(CompletionBlock)completionBlock;
  ```
  >**微信发起支付**

  ```
/*! @brief 发送请求到微信，等待微信返回onResp
 *
 * 函数调用后，会切换到微信的界面。第三方应用程序等待微信返回onResp。微信在异步处理完成后一定会调用onResp。支持以下类型
 * SendAuthReq、SendMessageToWXReq、PayReq等。
 * @param req 具体的发送请求，在调用函数后，请自己释放。
 * @return 成功返回YES，失败返回NO。
 */
+(BOOL) sendReq:(BaseReq*)req;
  ```
  -  （4）支付宝发起支付不单单传入订单信息，还需要传入appSchemes（就是在Info - URL Types 中配置的 App Schemes），而微信 发起支付只需要传入订单信息，它的appSchemes 在 `didFinishLaunchingWithOptions` 注册的时候已经传入了，因此可以考虑 我也在`didFinishLaunchingWithOptions` 中给支付宝绑定一个 appSchemes ，类似微信，然后在发起支付的时候就不需要传入，只需要在内部获取就行，当然，由于Url Scheme 是存储在`Info.plist` 文件中，因此可以用代码获取，就不需要调用者传入了，只需要按照本工具的规定就搞定

  -  （5）支付宝的支付返回状态不是以枚举类型返回，是用过回调中返回的字典中的 resultStatus 字段，而微信是通过枚举返回，此时可以统一为枚举，可参考微信
![支付宝支付返回状态码-DWQ](http://upload-images.jianshu.io/upload_images/1085031-b8bca4159e811852.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

    ![微信支付返回状态码-DWQ](http://upload-images.jianshu.io/upload_images/1085031-fdb7932ac4d290db.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  -  （6）支付宝每一个状态码都对应一个状态信息，而微信则只有错误的时候（errCode = -1）才有对应状态信息，可参考支付宝，手动给微信添加返回状态信息

#三、集成
- **1、支付宝支付集成 （三个步骤）**
  -  （1）由于支付宝不支持Pod，那么[下载最新的SDK](https://doc.open.alipay.com/doc2/detail.htm?treeId=54&articleId=104509&docType=1)，拖到项目中

  ![SDK包含资源](http://upload-images.jianshu.io/upload_images/1085031-2ba9f31933ca4de0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  -  （2）按照官方文档指示，导入所需库

   
![支付宝依赖库.png](http://upload-images.jianshu.io/upload_images/2231137-8891a5433f072761.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



  -  （3）配置 `Info.plist` 中的 `Url Types` 添加支付宝跳转 Url Scheme

    ![添加Url Scheme](http://upload-images.jianshu.io/upload_images/1085031-d81ba0ffc1931385.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


- **2、微信支付集成（五个步骤）**
  -  （1）同样微信也不支持Pod，[下载最新的SDK](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=11_1)，拖到项目中

  ![有四个文件](http://upload-images.jianshu.io/upload_images/1085031-9db84ae06b2075fb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
  -  （2）按照微信官方文档，导入所需库：文档比较老，可参考Demo中的依赖库

   
![微信官方平台.png](http://upload-images.jianshu.io/upload_images/2231137-91abec4aada12f8b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


 

  -   （3）在 `build settings` 下面的 `Other Linker Flags` 添加 `-ObjC` ，

    ![添加-all_load](http://upload-images.jianshu.io/upload_images/1085031-4208755cadb0e2ba.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

  -  （4）配置 `Info.plist` 中的 `Url Types` 添加微信跳转 Url Scheme，此时就集成完毕了

  
![微信Schemes.png](http://upload-images.jianshu.io/upload_images/2231137-371854f90cf0458e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


  -  （5）添加UIKit框架。这样，微信支付就完美的集成上去了。


#四、封装 API 

 - 1、单例模式，项目中唯一，方便统一管理

```
/**
 *  @author 杜文全
 *
 *  单例管理
 */
+ (instancetype)shareManager;
```

- 2、处理回调url，需要在AppDelegate中实现

```
/**
 *  @author 杜文全
 *
 *  处理跳转url，回到应用，需要在delegate中实现
 */
- (BOOL)dwq_handleUrl:(NSURL *)url;
```

- 3、注册app，需要在 didFinishLaunchingWithOptions 中调用，绑定URL Scheme

```
/**
 *  @author 杜文全
 *
 *  注册App，需要在 didFinishLaunchingWithOptions 中调用
 */
- (void)dwq_registerApp;
```

- 4、发起支付，传入订单参数类型是id，传入如果是字符串，则对应是跳转支付宝支付；如果传入PayReq 对象，这跳转微信支付,注意，不能传入空字符串或者nil，内部有对应断言;统一了回调，不管是支付宝的wap 还是 app，或者是微信支付，都是通过这个block回调，回调状态码都有对应的状态信息

```
/**
 *  @author 杜文全
 *
 *  发起支付
 *
 * @param orderMessage 传入订单信息,如果是字符串，则对应是跳转支付宝支付；如果传入PayReq 对象，这跳转微信支付,注意，不能传入空字符串或者nil
 * @param callBack     回调，有返回状态信息
 */
- (void)dwq_payWithOrderMessage:(id)orderMessage callBack:(DWQCompleteCallBack)callBack;
```


#五、用法（基于SDK集成后）

-  **1、在`AppDelegate`处理回调，一般只需要实现后面两个方法即可，为了避免不必要的麻烦，最好三个都写上**

```
/**
 *  @author 杜文全
 *
 *  最老的版本，最好也写上
 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [DWQPAYMANAGER dwq_handleUrl:url];
}

/**
 *  @author 杜文全
 *
 *  iOS 9.0 之前 会调用
 */
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [DWQPAYMANAGER dwq_handleUrl:url];
}

/**
 *  @author 杜文全
 *
 *  iOS 9.0 以上（包括iOS9.0）
 */
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options{
    
    return [DWQPAYMANAGER fl_handleUrl:url];
}
```

- **2、在`didFinishLaunchingWithOptions`中注册 app，内部绑定根据Info中对应的Url Types 绑定 `URL Scheme`**

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 注册app
    [DWQPAYMANAGER dwq_registerApp];
    return YES;
}
```

- 3、**发起支付**

- 3.1  支付宝支付

```
NSString *orderMessage = @"Demo 中 有 可测试的 订单信息";
[DWQPAYMANAGER dwq_payWithOrderMessage:orderMessage callBack:^(FLErrCode errCode, NSString *errStr) {
   NSLog(@"errCode = %zd,errStr = %@",errCode,errStr);
}];
```

- 3.2 微信支付

```
//调起微信支付
 PayReq* req             = [[PayReq alloc] init];
 req.partnerId           = [dict objectForKey:@"partnerid"];
 req.prepayId            = [dict objectForKey:@"prepayid"];
 req.nonceStr            = [dict objectForKey:@"noncestr"];
 req.timeStamp           = stamp.intValue;
 req.package             = [dict objectForKey:@"package"];
 req.sign                = [dict objectForKey:@"sign"];
                
 [DWQPAYMANAGER dwq_payWithOrderMessage:req callBack:^(FLErrCode errCode, NSString *errStr) {
     NSLog(@"errCode = %zd,errStr = %@",errCode,errStr);
 }];
```

#六、封装特点
- 1、分离框架，统一进行操作和管理，方便维护

- 2、支付封装，使用更加简单便捷。

- 3、融合支付宝 和 微信 接口的优点，完善微信返回状态码对应的状态信息

- 4、对支付宝和微信的 回调处理都统一 成一个 block回调

- 5、封装中添加了比较完善的断言


  ```objective-c
// 回调url地址为空
#define DWQTIP_CALLBACKURL @"url地址不能为空！"
// 订单信息为空字符串或者nil
#define DWQTIP_ORDERMESSAGE @"订单信息不能为空！"
// 没添加 URL Types
#define DWQTIP_URLTYPE @"请先在Info.plist 添加 URL Type"
// 添加了 URL Types 但信息不全
#define DWQTIP_URLTYPE_SCHEME(name) [NSString stringWithFormat:@"请先在Info.plist 的 URL Type 添加 %@ 对应的 URL Scheme",name]

```


#七、提醒和Demo下载地址：
- 1、`Info.plist` 配置 `Url Types`  的 `Identifier` 必须 保证 和 工具中的对应，默认微信的 `Identifier` 是 `weixin` ，支付宝的 `Identifier` 是 `zhifubao`，可修改

  ```
/**
 *  @author 杜文全
 *
 *  此处必须保证在Info.plist 中的 URL Types 的 Identifier 对应一致
 */
#define DWQWECHATURLNAME @"weixin"
#define DWQALIPAYURLNAME @"zhifubao"
  ```

- 2、因为工具中添加了比较完善的断言，配置不完整或者是传参不正确，程序都会不可避免的崩溃
