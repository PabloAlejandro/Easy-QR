//
//  ViewController.m
//  Easy-QR
//
//  Created by Pau on 01/04/2015.
//  Copyright (c) 2015 PabloAlejandro. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>

@end

@implementation ViewController {
    AVCaptureSession *session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Class private methods

- (void)setup
{
    [self registerNotifications];
    
    [self capture];
}

- (void)registerNotifications
{
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(applicationDidEnterBackground:)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(applicationDidBecomeActive:)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

- (void)applicationDidEnterBackground:(id)sender
{
    NSLog(@"%s", __func__);
    
    [session stopRunning];
}

- (void)applicationDidBecomeActive:(id)sender
{
    NSLog(@"%s", __func__);
    
    [session startRunning];
}

- (void)capture
{
    session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"%s: %@", __func__, error);
        return;
    }
    
    [session addInput:input];
    
    //Add the metadata output device
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:output];
    
    //You should check here to see if the session supports these types, if they aren't support you'll get an exception
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    output.rectOfInterest = self.view.bounds;
    
    AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    newCaptureVideoPreviewLayer.frame = self.view.frame;
    //newCaptureVideoPreviewLayer.frame = [[UIScreen mainScreen] bounds];
    newCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:newCaptureVideoPreviewLayer above:self.view.layer];
    
    //Turn on point autofocus for middle of view
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [device lockForConfiguration:&error];
        CGPoint point = CGPointMake(0.5,0.5);
        [device setFocusPointOfInterest:point];
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device unlockForConfiguration];
    }
    
    //[session startRunning];
}

#pragma mark - <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [session startRunning];
}

#pragma mark - <AVCaptureMetadataOutputObjectsDelegate>

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [session stopRunning];
    
    AVMetadataObject *metadata = [metadataObjects firstObject];
    NSString *code =[(AVMetadataMachineReadableCodeObject *)metadata stringValue];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QR found"
                                                    message:code
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    
    /*for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *code =[(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            NSLog(@"%s: %@", __func__, code);
        }
    }*/
}

@end
