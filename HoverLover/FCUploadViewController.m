//
//  FCUploadViewController.m
//  HoverLover
//
//  Created by adam liu on 5/3/14.
//  Copyright (c) 2014 www.xhiyu.com. All rights reserved.
//

#import "FCUploadViewController.h"
#import "MBProgressHUD.h"


@interface FCUploadViewController (){
    MBProgressHUD *HUD;
    MBProgressHUD *refreshHUD;
    MBProgressHUD *waitingHUD;
    bool isLocated;
    NSString * currentAddress;
    double latitude;
    double longitude;
    NSString * currentCity;
}

@end

@implementation FCUploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.uiLocationBackground.layer.cornerRadius = 5;
    self.uiPicViewBackground.layer.cornerRadius = 5;
    self.uitextview.layer.cornerRadius = 5;
    self.uitextview.delegate = self;
    
//    self.uiUploadImg.contentMode = UIViewContentModeScaleAspectFill;  //Over Bounce,keep scale
//    self.uiUploadImg.contentMode = UIViewContentModeScaleAspectFit;   //keep scale,no fill whole view
    self.uiUploadImg.contentMode = UIViewContentModeScaleToFill;
    self.uiUploadImg.image = self.imageFromFather;
    
    NSLog(@"%f",self.father_latitude);
    NSLog(@"%f",self.father_longitude);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)postSend:(id)sender {
    [self.uitextview resignFirstResponder];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIImage * image = [self scaleImage:self.imageFromFather toScale:0.5];
    
    NSData *pictureData = UIImageJPEGRepresentation(image, 0.4);

    [self uploadImage:pictureData];
}

-(UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width*scaleSize,image.size.height*scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height *scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (IBAction)locatePress:(id)sender {
    waitingHUD = [[MBProgressHUD alloc] initWithView:[self.navigationController.view window]];
    [[self.navigationController.view window] addSubview:waitingHUD];
    waitingHUD.delegate = self;
    waitingHUD.labelText = @"Locating...";
    [waitingHUD show:YES];
    
    //    __block NSString *string;
    [[MMLocationManager shareLocation] getCity:^(NSString *addressString) {
        currentCity = addressString;
        self.uiLocationLabel.text = currentCity;
    }];
    
    [[MMLocationManager shareLocation] getLocationCoordinate:^(CLLocationCoordinate2D locationCorrrdinate) {
        latitude = locationCorrrdinate.latitude;
        longitude = locationCorrrdinate.longitude;
    } withAddress:^(NSString *addressString) {
        currentAddress = addressString;
        [self hudWasHidden:waitingHUD];
        [waitingHUD hide:NO];
        isLocated = YES;
    }];
}

- (void)uploadImage:(NSData *)imageData
{
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading";
    [HUD show:YES];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            //Hide determinate HUD
            [HUD hide:YES];
            
            /*
            // Show checkmark
            HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.view addSubview:HUD];
            
            // Set custom view mode
            HUD.mode = MBProgressHUDModeDeterminate;
            
            HUD.delegate = self;
            */
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userPhoto = [PFObject objectWithClassName:KEY_OBJECT];
            [userPhoto setObject:imageFile forKey:KEY_IMAGE];
            
            // Set the access control list to current user for security purposes
            //userPhoto.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            //PFUser *user = [PFUser currentUser];
            [userPhoto setObject:[[UIDevice currentDevice] name] forKey:KEY_USER];
            
            [userPhoto setObject:self.uitextview.text forKey:KEY_COMMENT];

            //Handle the location
            if(isLocated){
                PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:latitude longitude:longitude];
                [userPhoto setObject:point forKey:KEY_GEOLOC];
                
                [userPhoto setObject:currentAddress forKey:KEY_FULL_ADDRESS];
                
                [userPhoto setObject:currentCity forKey:KEY_CITY];
            }else{
                //default location is kowloon tong
                //22.3332348,114.1836379
                PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:22.3332348 longitude:114.1836379];
                [userPhoto setObject:point forKey:KEY_GEOLOC];
                [userPhoto setObject:@"Hong Kong,Kowloon,Kowloon Tong" forKey:KEY_FULL_ADDRESS];
                [userPhoto setObject:@"Kowloon Tong" forKey:KEY_CITY];
            }
            
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    [self showErrorView:[NSString stringWithFormat:@"Error: %@ %@", error, [error userInfo]]];
                }
            }];
        }
        else{
            [HUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [self showErrorView:[NSString stringWithFormat:@"Error: %@ %@", error, [error userInfo]]];
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        HUD.progress = (float)percentDone/100;
    }];
}

-(void)refresh{
    
}

#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD hides
    [HUD removeFromSuperview];
	HUD = nil;
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView{
    if (textView.text.length == 0) {
        self.uiTextPlaceholder.text = @"Type your words here....";
    }else{
        self.uiTextPlaceholder.text = @"";
    }
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    self.uiTextPlaceholder.text = @"";
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
    }
    return YES;
}

-(void)showErrorView:(NSString *)errorMsg{
    
    UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [errorAlertView show];
}
@end
