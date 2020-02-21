//
//  LiveViewController.m
//  LiveDemoiOS
//
//  Created by feinno on 2020/2/21.
//  Copyright © 2020 feinno. All rights reserved.
//

#import "LiveViewController.h"
#import "LivePushViewController.h"
#import "LivePlayViewController.h"

@interface LiveViewController () <UITextFieldDelegate>

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    
}


- (void)onBtnClick:(UIButton *)button {
    NSString * text = [self contentWithTag:1];
    if (!text.length) {
        [MBProgressHUD showHUDWith:@"请输入房间号" view:self.view];
        return;
    }
    
    if (button.tag == 1) {
        LivePushViewController * vc = [[LivePushViewController alloc] init];
        vc.roomId = text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        LivePlayViewController * vc = [[LivePlayViewController alloc] init];
        vc.roomId = text;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    
}

- (void)setContent:(NSString *)content tag:(NSInteger)tag {
    UITextField * textField = [self.view viewWithTag:tag];
    textField.text = content;
}

- (NSString *)contentWithTag:(NSInteger)tag {
    UITextField * textField = [self.view viewWithTag:tag];
    return textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)setupViews {
    [self createTitleWithName:@"直播"];
    //@WeakObj(self)
    
    CGFloat space = 30;//logo与输入框的距离
    UIImageView * logoImageView = [[UIImageView alloc] init];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:logoImageView];
    logoImageView.image = [UIImage imageNamed:@"logo"];
    [logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(space + WholeNavigationBarHeight);
        make.centerX.mas_equalTo(0);
        
    }];
    
    
    CGFloat margin = 10;//左右间距
    CGFloat titleW = 80;//标题宽度
    CGFloat titleH = 40;//高度
    NSArray * titles = @[@"房间ID"];
    UIView * topView = logoImageView;
    for (int i = 0; i < titles.count; i++) {
        UILabel * label = [[UILabel alloc] init];
        label.font = FONT(15);
        label.textAlignment = NSTextAlignmentRight;
        [self.view addSubview:label];
        label.text = titles[i];
        
        UITextField * textField = nil;
        textField = [[UITextField alloc] init];
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.font = FONT(15);
        [self.view addSubview:textField];
        textField.tag = i + 1;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(topView.mas_bottom).offset(i == 0 ? space : margin);
            make.left.mas_equalTo(margin);
            make.width.mas_equalTo(titleW);
            make.height.equalTo(textField.mas_height);
        }];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(label.mas_top).offset(0);
            make.left.equalTo(label.mas_right).offset(margin);
            make.right.mas_equalTo(-margin);
            make.height.mas_equalTo(titleH);
        }];
        
        topView = textField;
    }
    
    UIButton * leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    leftBtn.tag = 1;
    leftBtn.titleLabel.font = FONT(18);
    [leftBtn setBackgroundImage:[UIImage imageWithColor:Main_Color] forState:UIControlStateNormal];
    leftBtn.layer.masksToBounds = YES;
    leftBtn.layer.cornerRadius = 20;
    [self.view addSubview:leftBtn];
    [leftBtn setTitle:@"主播端" forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [leftBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(2*margin);
        make.width.mas_equalTo(120);
        make.bottom.mas_equalTo(-(BottomSafeHeight + 100));
        make.height.mas_equalTo(40);
    }];
    
    UIButton * rightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    rightBtn.tag = 2;
    rightBtn.titleLabel.font = FONT(18);
    [rightBtn setBackgroundImage:[UIImage imageWithColor:Main_Color] forState:UIControlStateNormal];
    rightBtn.layer.masksToBounds = YES;
    rightBtn.layer.cornerRadius = 20;
    [self.view addSubview:rightBtn];
    [rightBtn setTitle:@"观众端" forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(120);
        make.right.mas_equalTo(-2*margin);
        make.bottom.mas_equalTo(-(BottomSafeHeight + 100));
        make.height.mas_equalTo(40);
    }];
    
    
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
