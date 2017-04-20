//
//  PhonenumberVC.m
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import "PhonenumberVC.h"
#import "SPServerManager.h"
#import "ConfirmCodeVC.h"
#import "MBProgressHUD.h"

@interface PhonenumberVC ()

@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation PhonenumberVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    //    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.lbl_warn setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) hideKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Navigation
- (IBAction)onGetCode:(id)sender {
    self.progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.labelText = @"Please wait...";

    [[SPServerManager sharedInstance] getSmsCode:self.txt_phoneNumber.text complete:^(BOOL success, SPAPIResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            if(success) {
                [self.lbl_warn setHidden:YES];
                [self performSegueWithIdentifier:@"gotoConfirmCode" sender:self];
            } else {
                [self.lbl_warn setHidden:NO];
            }
        });
    }];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sende
{
    return NO;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.destinationViewController isKindOfClass:ConfirmCodeVC.class]) {
        ConfirmCodeVC *vc = segue.destinationViewController;
        vc.phoneNumber = self.txt_phoneNumber.text;
    }
}

@end
