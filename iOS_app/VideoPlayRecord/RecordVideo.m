//
//  RecordVideo.m
//  VideoPlayRecord
//
//  Created by Abdul Azeem Khan on 5/9/12.
//  Copyright (c) 2012 DataInvent. All rights reserved.
//

#import "RecordVideo.h"
#import <CoreMotion/CoreMotion.h>

CMMotionManager *motionManager;
CMAttitude *referenceAttitude;
NSMutableArray *gyroDataStream;

@implementation RecordVideo
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self dismissModalViewControllerAnimated: YES];
}
- (IBAction)RecordAndPlay:(id)sender {
    [self startCameraControllerFromViewController: self
                                    usingDelegate: self];
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(onTick:)
                                   userInfo:nil
                                    repeats:NO];
}

-(void)onTick:(NSTimer *)timer {
    motionManager = [[CMMotionManager alloc] init];
    referenceAttitude = nil;
//    NSMutableArray *gyroDataStream = [NSMutableArray arrayWithObjects:@[@0,@0,@0], nil];
    gyroDataStream = [[NSMutableArray alloc] init];
    NSLog(@"Gyroscope Available!");

    //Gyroscope
    if([motionManager isGyroAvailable])
    {
        /* Start the gyroscope if it is not active already */
        if([motionManager isGyroActive] == NO)
        {
            /* Update us 2 times a second */
            [motionManager setGyroUpdateInterval:1.0f / 30.0f];
            
            /* Add on a handler block object */
            
            /* Receive the gyroscope data on this block */
            [motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMGyroData *gyroData, NSError *error)
             {
                 NSArray *gyroAxisData = @[
                                           [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]* 1000.0],
                                           [NSNumber numberWithDouble:gyroData.rotationRate.x],
                                           [NSNumber numberWithDouble:gyroData.rotationRate.y],
                                           [NSNumber numberWithDouble:gyroData.rotationRate.z]
                                           ];
                 [gyroDataStream addObject:gyroAxisData];
                 NSLog( @"%@",[[gyroDataStream lastObject] componentsJoinedByString:@", "]);

//                 NSLog(@"Gyroscope Available!");
             }];

        }
    }
    else
    {
        NSLog(@"Gyroscope not Available!");
    }
}

- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose movie capture
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    
    cameraUI.delegate = delegate;
    
    [controller presentModalViewController: cameraUI animated: YES];
    return YES;
}


// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    [self dismissModalViewControllerAnimated:NO];
    
    // Handle a movie capture
    if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0)
        == kCFCompareEqualTo) {
        
        NSString *moviePath = [[info objectForKey:
                                UIImagePickerControllerMediaURL] path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum (moviePath,self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        
        
    }
    [motionManager stopGyroUpdates];
    NSLog( @"%@",[gyroDataStream componentsJoinedByString:@" FINAL, "]);
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil, nil];
        [alert show];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"  delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
}

@end
