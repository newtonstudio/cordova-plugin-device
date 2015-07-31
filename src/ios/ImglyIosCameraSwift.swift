//
//  ImglySwift.swift
//  UR
//
//  Created by Shaw ChunLee on 2015/7/27.
//
//

import UIKit
import imglyKit
import Foundation

public typealias IMGLYCameraCompletionBlock = (UIImage?) -> (Void)

@objc public class ImglyIosCameraSwift :CDVPlugin{
    
   
    let cameraViewController = IMGLYCameraViewController()
    var CDVcommand : CDVInvokedUrlCommand?
    var CDVcommandDelegate : CDVCommandDelegate?
    var cameraView : UIViewController?
    
    override public class func `new`() -> ImglyIosCameraSwift {
        return ImglyIosCameraSwift()
    }
    
    public var leavecompletionBlock: IMGLYCameraCompletionBlock?
    
    func callCamera(cameraController: UIViewController, cdvstr command: CDVInvokedUrlCommand, CDVdelegate mydelegate : CDVCommandDelegate ) {
        
        //UIApplication.sharedApplication().delegate as! AppDelegate
        CDVcommandDelegate = mydelegate
        cameraView = cameraController;
        CDVcommand = command
        
        cameraViewController.leavecompletionBlock = editorCompletionBlock
        //myCamera.presentViewController(editorViewController, animated: true, completion: nil)
        /*let navigationController = IMGLYNavigationController(rootViewController: cameraViewController)
        navigationController.navigationBar.barStyle = .Black
        navigationController.navigationBar.translucent = false
        navigationController.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : UIColor.whiteColor() ]*/
        
        cameraController.presentViewController(cameraViewController, animated: true, completion: nil)
     
        
    }
    
    
    public func editorCompletionBlock(result: IMGLYEditorResult, image: UIImage?) {
        
        var myObjClass:ImglyIosCamera = ImglyIosCamera()
        myObjClass.commandDelegate = CDVcommandDelegate
        myObjClass.capturedImageWithPath(image,cameraController: cameraViewController,CDVString: CDVcommand)
        
        //cameraView?.dismissViewControllerAnimated(true, completion: {})
    }
    
}