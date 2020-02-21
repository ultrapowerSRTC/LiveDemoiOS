//
//  LivePushViewController.m
//  LiveDemoiOS
//
//  Created by feinno on 2020/2/21.
//  Copyright © 2020 feinno. All rights reserved.
//

#import "LivePushViewController.h"


@interface LivePushViewController () <FeinnoMegLibPusherDelegate>
@property (nonatomic ,strong) SRTCLiveCommonParams *params;
@property (nonatomic, strong)FeinnoMegLib * manager;

@property (nonatomic, strong)UIView * videoView;//画布
@property (nonatomic, strong)MBProgressHUD * hud;

@property (nonatomic, strong)UIButton * closeBtn;

@end

@implementation LivePushViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if (self.isPortrait) {
        [self setDeviceInterfaceOrientationPortrait];
    } else {
        [self setDeviceInterfaceOrientationLeft];//设备向左强转，画面相对向右
        [_manager setLivePushOutputImageOrientation:UIInterfaceOrientationLandscapeRight];//强转屏幕方向，需要主动设置画面方向
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:false];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    //恢复竖屏
    if (!self.isPortrait) {
        [self setDeviceInterfaceOrientationPortrait];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.canSideBack = NO;
    [self setupViews];
    
    [self initParams];
    
    [self initSRTCLivePusher];
    
    [self startLive];
}

- (void)initParams {
    [self params];
   
    _params.uccId = [MyUser sharedInstance].uccId;
    _params.channelName = [_roomId longLongValue];
    _params.name = @"测试直播名称";
    _params.desc = @"测试直播名称";
    _params.live1 = 1;
    _params.live2 = 1;
    _params.definition = @"720x1280";
    _params.password = @"";
    _params.isPrivate = NO;
    _params.auth = NO;
    _params.nickName = [MyUser sharedInstance].nickName;
    
}

- (void)initSRTCLivePusher {
   
    self.manager = [FeinnoMegLib sharedInstance];
    
    SRTCLivePusherProfile profile = SRTC_PusherProfile_360P;
    if ([self.params.definition rangeOfString:@"540"].length) {
        profile = SRTC_PusherProfile_540P;
    } else if ([self.params.definition rangeOfString:@"720"].length) {
        profile = SRTC_PusherProfile_720P;
    }
    if (self.isPortrait) {
        [self.manager initVerticalPusherWithDefaultConfig:profile delegate:self];
    } else {
        [self.manager initHorizontalPusherWithDefaultConfig:profile delegate:self];
    }
    
    [self.manager setupPusherPreView:self.videoView];//设置画布
    [self.manager startPusherPreview];//开始预览
}

- (void)startLive {
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
    [_hud setHUDModeToIndeterminateWithText:@"正在准备..."];
//    @WeakObj(self);
    [self.manager createLiveRoom:self.params success:^(id  _Nullable response) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [selfWeak createLiveSuccess];
//            [selfWeak reciveRoomInfo:response];
//        });
    } faild:^(NSInteger rspCode, NSError * _Nullable error, NSString * _Nullable step) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hideRightNow];

            NSString *message = [NSString stringWithFormat:@"%@ 出错\n 错误码: %ld\n 错误信息: %@", step, (long)rspCode, error.localizedDescription];
            [UIAlertController showConfirmAlertWithMessage:message vc:self];
        });
        
    }];
}

- (BOOL)isPortrait {
    NSArray * definitionHV = [_params.definition componentsSeparatedByString:@"x"];
    if ([definitionHV.firstObject intValue] < [definitionHV.lastObject intValue]) {
        return YES;
    } else {
        return NO;
    }
}


- (void)leaveLiveRoom {
    [_manager quitLiveRoomSuccess:^(id  _Nullable response) {
        
    } faild:^(NSInteger rspCode, NSError * _Nullable error, NSString * _Nullable step) {
        
    }];
    [_manager destroy];
    _manager = nil;
   
}

- (void)closeClick {
    [UIAlertController showAlertStyleWithTitle:@"提示" message:@"确定要退出直播吗？" leftText:@"取消" rightText:@"确定" vc:self leftHandler:nil rightHandler:^{
        [self leaveLiveRoom];
        [self back];
    }];
}

- (void)setupViews {
    _videoView = [[UIView alloc] init];
    _videoView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_videoView];
    [_videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(closeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeBtn];
    [_closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-20);
        make.bottom.mas_equalTo(-(BottomSafeHeight + 10));
        make.size.mas_equalTo(CGSizeMake(36, 36));
    }];
}

#pragma mark -
#pragma mark - FeinnoMegLibLivePusherDelegate
/** 推流中 */
- (void)FeinnoMegLibPusherDidStart:(FeinnoMegLib *)manager {
    [_hud hideRightNow];
    [MBProgressHUD showHUDWith:@"开始推流" view:self.view];
}

/** 推流结束 */
- (void)FeinnoMegLibPusherDidStop:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"推流结束" view:self.view];
}

/** 错误回调 */
- (void)FeinnoMegLib:(FeinnoMegLib *)manager errorCode:(SRTCLiveErrorCode)errorCode {
    NSString *text = @"未知错误";
    if (errorCode == SRTCLiveError_PreViewFaild) {
        text = @"预览失败";
    } else if (errorCode == SRTCLiveError_GetStreamInfo) {
        text = @"获取流媒体信息失败";
    } else if (errorCode == SRTCLiveError_ConnectSocket) {
        text = @"连接socket失败";
    } else if (errorCode == SRTCLiveError_Verification) {
        text = @"服务器验证失败";
    } else if (errorCode == SRTCLiveError_ReConnectTimeOut) {
        text = @"重新连接服务器超时";
    }
    [self leaveLiveRoom];
    [UIAlertController showConfirmAlertWithMessage:text vc:self handler:^{
        [self back];
    }];
}

- (void)FeinnoMegLibPusherNetConnectionDidLost:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"网络断开" view:self.view];
    [self leaveLiveRoom];
    [UIAlertController showConfirmAlertWithMessage:@"网络断开" vc:self handler:^{
        [self back];
    }];
}

- (void)FeinnoMegLibPusherNetConnectionDidRecovery:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"网络恢复" view:self.view];
}

- (SRTCLiveCommonParams *)params {
    if (!_params) {
        _params = [[SRTCLiveCommonParams alloc] init];
    }
    return _params;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
