//
//  ConfirmCodeVC.h
//  8a-ios
//
//  Created by Kristoffer Yap on 4/21/17.
//  Copyright © 2017 Allfree Group LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfirmCodeVC : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txt_code;

@property (nonatomic, strong) NSString* phoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *lbl_warning;

@end
