//
//  FCUploadViewController.h
//  HoverLover
//
//  Created by adam liu on 5/3/14.
//  Copyright (c) 2014 www.xhiyu.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "MMLocationManager.h"
#import <Parse/Parse.h>

@interface FCUploadViewController : UIViewController<UITextViewDelegate,MBProgressHUDDelegate,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *uiTextPlaceholder;
@property (weak, nonatomic) IBOutlet UITextView *uitextview;
@property (weak, nonatomic) IBOutlet UIView *uiPicViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *uiUploadImg;
@property (weak, nonatomic) IBOutlet UIView *uiLocationBackground;
@property (weak, nonatomic) IBOutlet UILabel *uiLocationLabel;

@property(nonatomic,assign)float father_latitude;
@property(nonatomic,assign)float father_longitude;

@property (strong, nonatomic) UIImage * imageFromFather;

- (IBAction)postSend:(id)sender;
- (IBAction)locatePress:(id)sender;

@end
