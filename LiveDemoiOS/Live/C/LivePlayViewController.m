//
//  LivePlayViewController.m
//  LiveDemoiOS
//
//  Created by feinno on 2020/2/21.
//  Copyright © 2020 feinno. All rights reserved.
//

#import "LivePlayViewController.h"

@interface LivePlayViewController () <FeinnoMegLibPlayerDelegate>

@property (nonatomic, strong)UIView * videoView;//画布
@property (nonatomic, strong)UIButton * closeBtn;

@property (assign, nonatomic) BOOL appNetIsLost;//网络是否丢失(未连接)
@property (nonatomic, strong) FeinnoMegLib * manager;


@end

@implementation LivePlayViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:false];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.canSideBack = NO;
    [self setupViews];
    
    [self initSRTCLivePlayer];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)initSRTCLivePlayer {
    _manager = [FeinnoMegLib sharedInstance];
    
    [self.manager initPlayerWithDefaultConfig:self.videoView delegate:self];
    
    SRTCLiveParams * params = [SRTCLiveParams new];
    params.channelName = [_roomId longLongValue];
    params.uccId = [MyUser sharedInstance].uccId;

    @WeakObj(self);
    [self.manager enterLiveRoom:params success:^(id  _Nullable response) {
        [selfWeak reciveRoomInfo:response];

    } faild:^(NSInteger rspCode, NSError * _Nullable error, NSString * _Nullable step) {
        NSString *message = [NSString stringWithFormat:@"%@ 错误 \n 错误码: %ld \n 错误原因: %@\n", step, (long)rspCode, error.domain];
        [UIAlertController showConfirmAlertWithMessage:message vc:self];
    }];
}

- (void)reciveRoomInfo:(id)response {
    
}

- (void)leaveLiveRoom {
   
    [_manager quitLiveRoomSuccess:^(id  _Nullable response) {
        
    } faild:^(NSInteger rspCode, NSError * _Nullable error, NSString * _Nullable step) {
    
    }];
    [_manager destroy];
    _manager = nil;
}

- (void)back {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)closeClick {
    [UIAlertController showAlertStyleWithTitle:@"提示" message:@"确定要退出直播吗？" leftText:@"取消" rightText:@"确定" vc:self leftHandler:nil rightHandler:^{
        [self leaveLiveRoom];
        [self back];
    }];
}

- (void)setupViews {
    _videoView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _videoView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_videoView];
    
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

- (void)onAppDidEnterBackGround:(UIApplication*)app {
    if ([[FeinnoMegLib sharedInstance] isPlaying]) {
        [[FeinnoMegLib sharedInstance] pausePlayer];
    }
}

- (void)onAppDidBecomeActive:(UIApplication*)app {
    if (!_appNetIsLost) {//网络未丢失状态下刷新
        [_manager refreshLivePlay];
    }
}

#pragma mark - FeinnoMegLibLivePlayerDelegate
/** 拉流开始 */
- (void)FeinnoMegLibPlayerDidStart:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"直播开始" view:self.view];
    [[UIApplication sharedApplication] setIdleTimerDisabled:true];

}
/** 拉流结束 */
- (void)FeinnoMegLibPlayerDidStop:(FeinnoMegLib *)manager info:(nullable NSDictionary *)info {
    [MBProgressHUD showHUDWith:@"直播结束" view:self.view];
    [[UIApplication sharedApplication] setIdleTimerDisabled:false];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self leaveLiveRoom];
    });
}

/** 主播暂停推流 */
- (void)FeinnoMegLibPlayerdidPause:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"直播已暂停" view:self.view];
}

/** 主播恢复推流 */
- (void)FeinnoMegLibPlayerdidResume:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"直播已恢复" view:self.view];
}

/** 主播在推流，但拉流端加载不到; 主播异常断开推流，但直播间还在。  拉流中或重连中 */
- (void)FeinnoMegLibPlayerisLoading:(FeinnoMegLib *)manager {
    
}

- (void)FeinnoMegLibPlayerNetConnectionDidLost:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"网络断开" view:self.view];
    _appNetIsLost = YES;
}

- (void)FeinnoMegLibPlayerNetConnectionDidRecovery:(FeinnoMegLib *)manager {
    [MBProgressHUD showHUDWith:@"网络恢复" view:self.view];
    _appNetIsLost = NO;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        //网络恢复时 如果应用是在活跃状态时刷新，前台不活跃时或后台时在进入活跃状态的时候再刷新，
        [_manager refreshLivePlay];
    }
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
