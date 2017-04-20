//
//  RootViewController.m
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import "RootViewController.h"
#import "SPServerManager.h"

#define GOTO_PROFILE    @"gotoProfileFromRoot"
#define GOTO_PHONE      @"gotoPhone"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem *loggedButton;
    if([[SPServerManager sharedInstance] isLoggedIn]) {
        loggedButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_user"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoProfile)];
    } else {
        loggedButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_logout"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoLogin)];
    }
    self.navigationItem.rightBarButtonItem = loggedButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onWatch:(id)sender {
    if([[SPServerManager sharedInstance] isLoggedIn]) {
        [self performSegueWithIdentifier:GOTO_PROFILE sender:self];
    } else {
        [self performSegueWithIdentifier:GOTO_PHONE sender:self];
    }
}
- (IBAction)onRequest:(id)sender {
    if([[SPServerManager sharedInstance] isLoggedIn]) {
        [self performSegueWithIdentifier:GOTO_PROFILE sender:self];
    } else {
        [self performSegueWithIdentifier:GOTO_PHONE sender:self];
    }
}

- (void) gotoLogin {
    [self performSegueWithIdentifier:GOTO_PHONE sender:self];
}

-(void) gotoProfile {
    [self performSegueWithIdentifier:GOTO_PROFILE sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return NO;
}

@end
