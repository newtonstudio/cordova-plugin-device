//
//  CustomCamera.h
//  UR
//
//  Created by Shaw ChunLee on 2015/7/27.
//
//

#import <Cordova/CDV.h>
@interface ImglyIosCamera : CDVPlugin

// Cordova command method
-(void) openCamera:(CDVInvokedUrlCommand*)command;

// Create and override some properties and methods (these will be explained later)
-(void) capturedImageWithPath:(UIImage*)image cameraController:(UIViewController*)currentcontroller CDVString:(CDVInvokedUrlCommand*)cdvstring;

@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;
@property (readwrite, assign) BOOL hasPendingOperation;


@end
