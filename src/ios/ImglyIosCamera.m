//
//  CustomCamera.m
//  UR
//
//  Created by Shaw ChunLee on 2015/7/27.
//
//

#import "ImglyIosCamera.h"
#import "UR-Swift.h"

@implementation ImglyIosCamera

// Cordova command method
-(void) openCamera:(CDVInvokedUrlCommand *)command {
   
    [self.commandDelegate runInBackground:^{
        
        self.hasPendingOperation = YES;
        
        ImglyIosCameraSwift *instance = [ImglyIosCameraSwift new];
        [instance callCamera:self.viewController cdvstr:command  CDVdelegate:self.commandDelegate];
        
    }];
    
}

// Method called by the overlay when the image is ready to be sent back to the web view
-(void) capturedImageWithPath:(UIImage*)image cameraController:(UIViewController*)currentcontroller CDVString:(CDVInvokedUrlCommand*)command{
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* filename = @"ImglyIosCamera.jpg";
    NSString* imagePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    // Get the image data (blocking; around 1 second)
    NSData* imageData = UIImageJPEGRepresentation(image, 0.5);
    
    // Write the data to the file
    [imageData writeToFile:imagePath atomically:YES];
    
    NSString *base64 = [[NSString alloc]initWithFormat:@"%@",[imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
    
    //[self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:imagePath] callbackId:self.latestCommand.callbackId];
    // EDIT 3/26/2015: It is now required to add the "file" protocol, as shown below.  Thanks Paul Clegg!
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64] callbackId:command.callbackId];
    
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
        // Hide the picker view
    [currentcontroller dismissModalViewControllerAnimated:YES];
}

@end
