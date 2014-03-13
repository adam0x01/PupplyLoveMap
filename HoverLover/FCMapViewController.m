//
//  FCMapViewController.m
//  HoverLover
//
//  Created by adam liu on 27/2/14.
//  Copyright (c) 2014 www.xhiyu.com. All rights reserved.
//

#import "FCMapViewController.h"
#import "JPSThumbnailAnnotation.h"
#import "FCUploadViewController.h"
#import "SJAvatarBrowser.h"
#include <stdlib.h>

@interface FCMapViewController (){
    MBProgressHUD *refreshHUD;
    NSMutableArray * annotationsToAdd;
    bool isTagTheMap;
    CLLocationCoordinate2D cordinate2dToUploadView;
}

@end

@implementation FCMapViewController{
    BOOL isCameraAvailable;
}

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
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        isCameraAvailable = YES;
    }
    [self.navigationController.navigationBar setTranslucent:YES];
    
    //the first time to load the photos
    annotationsToAdd = [[NSMutableArray alloc] init];
    
    //add gestureRecognizer to map
    
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    
    tapRecognizer.numberOfTapsRequired = 1;
    
    tapRecognizer.numberOfTouchesRequired = 1;
    
//    [self.mpv addGestureRecognizer:tapRecognizer];
    
    
//    //load the photos from server,and update the annotationsToAdd.
//    [self loadPhotos];
}

-(void)viewDidAppear:(BOOL)animated{
    [self.mpv removeAnnotations:self.mpv.annotations];
    [self loadPhotos];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self.mpv];
    
    CLLocationCoordinate2D tapPoint = [self.mpv convertPoint:point toCoordinateFromView:self.view];
    
    MKPointAnnotation *point1 = [[MKPointAnnotation alloc] init];
    point1.coordinate = tapPoint;
    
    isTagTheMap = YES;
    cordinate2dToUploadView = tapPoint;
    
    //call the IBAction method
    [self postSomething:nil];
    [self.mpv addAnnotation:point1];
}

- (IBAction)postSomething:(id)sender {
    UIActionSheet *myActionSheet1=[[UIActionSheet alloc] initWithTitle:@"Post Mood" delegate:self cancelButtonTitle:@"Cancle" destructiveButtonTitle:nil otherButtonTitles:@"From Camera", @"From Library", nil];
    [myActionSheet1 showInView:[self.view window]];
}

- (IBAction)refreshBtn:(id)sender {
    [self.mpv removeAnnotations:self.mpv.annotations];
    [self loadPhotos];
}

-(void)loadPhotos{
    
    refreshHUD = [[MBProgressHUD alloc] initWithView:[self.navigationController.view window]];
    [[self.navigationController.view window] addSubview:refreshHUD];
	
    // Register for HUD callbacks so we can remove it from the window at the right time
    refreshHUD.delegate = self;
	
    // Show the HUD while the provided method executes in a new thread
    [refreshHUD show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:KEY_OBJECT];
//    PFUser *user = [PFUser currentUser];
//    [query whereKey:@"user" equalTo:user];
    [query orderByAscending:KEY_CREATION_DATE];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
//               NSLog(@"%@",objects);
                annotationsToAdd = [objects mutableCopy];
                NSLog(@"%@",annotationsToAdd);
                [refreshHUD hide:YES];
                [self generateAnnotations];

        }else{
            [refreshHUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [self showErrorView:[NSString stringWithFormat:@"Error: %@ %@", error, [error userInfo]]];
            
        }
        
    }];
    
}

- (void)generateAnnotations {
    //keep the existing annotaion,and add the new annotaion to the map
    
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[annotationsToAdd count]];
    
    //Date format
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    //    [inputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [inputFormatter setLocale:[NSLocale currentLocale]];
    [inputFormatter setDateFormat:@"MMM-d"];
    
    for (PFObject *annotationObject in annotationsToAdd){
        
        JPSThumbnail *thumbnail = [[JPSThumbnail alloc] init];
        PFFile *image = (PFFile *)[annotationObject objectForKey:KEY_IMAGE];
        thumbnail.image = [UIImage imageWithData:image.getData];
        thumbnail.title = [annotationObject objectForKey:KEY_COMMENT];
        
        NSString * nowDate = [inputFormatter stringFromDate:annotationObject.createdAt];
        thumbnail.subtitle = [NSString stringWithFormat:@"From %@,at %@",[annotationObject objectForKey:KEY_USER],nowDate];
        
        PFGeoPoint *point = (PFGeoPoint *)[annotationObject objectForKey:KEY_GEOLOC];
        // rand the latitude and longtitue ,add rand 0.123456
        double r = arc4random() % 10;
//        NSLog(@"%f",(double)r*0.00001);
//        NSLog(@"%f",point.latitude + (double)r*0.00001);
//        NSLog(@"%f",point.longitude + (double)r*0.00001);
        thumbnail.coordinate = CLLocationCoordinate2DMake(point.latitude + (double)r*0.00001,point.longitude + (double)r*0.00001);
        thumbnail.disclosureBlock = ^{
//            NSLog(@"selected %@",[annotationObject objectForKey:KEY_ID]);
            [SJAvatarBrowser showImage:[[UIImageView alloc] initWithImage:[UIImage imageWithData:image.getData]]];
            
        };
        
//        //loop to add annotaions
//        JPSThumbnail *ottawa = [[JPSThumbnail alloc] init];
//        ottawa.image = [UIImage imageNamed:@"ottawa.jpg"];
//        ottawa.title = @"Parliament of Canada";
//        ottawa.subtitle = @"Oh Canada!";
//        ottawa.coordinate = CLLocationCoordinate2DMake(22.45, 113.60);
//        ottawa.disclosureBlock = ^{ NSLog(@"selected Ottawa"); };
//        
        [annotations addObject:[[JPSThumbnailAnnotation alloc] initWithThumbnail:thumbnail]];
        
        
    }
    
    [self.mpv addAnnotations:annotations];
//    return annotations;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        if (!isCameraAvailable) {
            [self showErrorView:@"Oosh,,,No camera here!"];
        }else{
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
            imgPicker.delegate = self;
            imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imgPicker.showsCameraControls = YES;
            [self presentViewController:imgPicker animated:YES completion:nil];
        }
    }else if(buttonIndex == 1){
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
        imgPicker.delegate = self;
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imgPicker animated:YES completion:nil];
        
        //        [self.navigationController presentModalViewController:imgPicker animated:YES];
        //        [self.navigationController presentViewController:imgPicker animated:YES completion:nil];
        //        [self.navigationController pushViewController:imgPicker animated:YES];
    }
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    //    PicUploadViewController * picupload = [[PicUploadViewController alloc] initWithNibName:@"xx" bundle:[NSBundle mainBundle]];
    //    picupload.uiimage.image =image;
    
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    FCUploadViewController* picupload = (FCUploadViewController *)[sb instantiateViewControllerWithIdentifier:@"picupload"];
    picupload.imageFromFather = image;
    
    //check isTagTheMap
    if (isTagTheMap) {
        picupload.father_latitude = cordinate2dToUploadView.latitude;
        picupload.father_longitude = cordinate2dToUploadView.longitude;
        isTagTheMap = NO;
    }
    [self dismissViewControllerAnimated:NO completion:^(void){
        [self.navigationController pushViewController:picupload animated:YES];
        NSLog(@"picker done!");
    }];
    
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didSelectAnnotationViewInMap:mapView];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view conformsToProtocol:@protocol(JPSThumbnailAnnotationViewProtocol)]) {
        [((NSObject<JPSThumbnailAnnotationViewProtocol> *)view) didDeselectAnnotationViewInMap:mapView];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation conformsToProtocol:@protocol(JPSThumbnailAnnotationProtocol)]) {
        return [((NSObject<JPSThumbnailAnnotationProtocol> *)annotation) annotationViewInMap:mapView];
    }
    return nil;
}


-(void)showErrorView:(NSString *)errorMsg{
    
    UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [errorAlertView show];
}

@end
