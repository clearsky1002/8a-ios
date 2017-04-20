//
//  ProfileVC.m
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import "ProfileVC.h"
#import "SPServerManager.h"
#import "MBProgressHUD.h"

@interface ProfileVC ()

@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation ProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *loggedButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_user"] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = loggedButton;
    
    self.navigationItem.hidesBackButton = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Navigation
- (IBAction)onLogout:(id)sender {
    self.progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.labelText = @"Please wait...";
    
    [[SPServerManager sharedInstance] logout:^(BOOL success, SPAPIResponse *response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    }];
    
}

- (IBAction)onCancel:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
