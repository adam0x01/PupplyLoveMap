//
//  FCMapViewController.h
//  HoverLover
//
//  Created by adam liu on 27/2/14.
//  Copyright (c) 2014 www.xhiyu.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MBProgressHUD.h"

@interface FCMapViewController : UIViewController <UIActionSheetDelegate,MKMapViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MBProgressHUDDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mpv;
- (IBAction)postSomething:(id)sender;
- (IBAction)refreshBtn:(id)sender;

@end
