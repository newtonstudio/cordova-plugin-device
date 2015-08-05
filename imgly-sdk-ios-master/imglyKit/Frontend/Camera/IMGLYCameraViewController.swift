//
//  IMGLYCameraViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 10/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

let InitialFilterIntensity = Float(0.75)
private let ShowFilterIntensitySliderInterval = NSTimeInterval(2)
private let FilterSelectionViewHeight = 100
private let BottomControlSize = CGSize(width: 47, height: 47)
public typealias IMGLYCameraCompletionBlock = (UIImage?) -> (Void)
public typealias IMGLYLeaveCompletionBlock = (IMGLYEditorResult, UIImage?) -> Void

public class IMGLYCameraViewController: UIViewController {
    
    // MARK: - Properties
    
    public private(set) lazy var topControlsView: UIView = {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        return view
        }()
    
    public private(set) lazy var cameraPreviewContainer: UIView = {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.clipsToBounds = true
        return view
        }()
    
    public private(set) lazy var bottomControlsView: UIView = {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        return view
        }()
    
    public private(set) lazy var flashButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "flash_auto", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.contentHorizontalAlignment = .Left
        button.addTarget(self, action: "changeFlash:", forControlEvents: .TouchUpInside)
        button.hidden = true
        return button
        }()
    
    public private(set) lazy var switchCameraButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.frame.size = CGSizeMake(21, 28);
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "ww_cam_switch", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.contentHorizontalAlignment = .Left
        button.addTarget(self, action: "switchCamera:", forControlEvents: .TouchUpInside)
        button.hidden = true
        return button
        }()

    public private(set) lazy var leaveCameraButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setTitle("Cancel", forState: UIControlState.Normal)
        button.contentHorizontalAlignment = .Left
        button.addTarget(self, action: "leaveCamera:", forControlEvents: .TouchUpInside)
        button.hidden = true
        return button
        }()

    
    public private(set) lazy var cameraRollButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "ww_photolist", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.imageView?.contentMode = .ScaleAspectFill
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: "showCameraRoll:", forControlEvents: .TouchUpInside)
        return button
        }()
    
    public private(set) lazy var takePhotoButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "ww_takephoto", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.imageView?.animationImages = [UIImage]()
        button.imageView?.animationRepeatCount = 1
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: "takePhoto:", forControlEvents: .TouchUpInside)
        
        /*let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "LensAperture_ShapeLayer_00000", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.imageView?.animationImages = [UIImage]()
        button.imageView?.animationRepeatCount = 1
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: "takePhoto:", forControlEvents: .TouchUpInside)
        
        for var index = 0; index < 10; index++ {
            let image = String(format: "LensAperture_ShapeLayer_%05d", index)
            button.imageView?.animationImages?.append(UIImage(named: image, inBundle: bundle, compatibleWithTraitCollection:nil)!)
        }*/
        
        return button
        }()
    
    public private(set) lazy var filterSelectionButton: UIButton = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let button = UIButton()
        button.setTranslatesAutoresizingMaskIntoConstraints(false)
        button.setImage(UIImage(named: "ww_editpreview", inBundle: bundle, compatibleWithTraitCollection: nil), forState: .Normal)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.addTarget(self, action: "toggleFilters:", forControlEvents: .TouchUpInside)
        button.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        return button
        }()
    
    public private(set) lazy var filterIntensitySlider: UISlider = {
        let bundle = NSBundle(forClass: self.dynamicType)
        let slider = UISlider()
        slider.setTranslatesAutoresizingMaskIntoConstraints(false)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.75
        slider.alpha = 0
        slider.addTarget(self, action: "changeIntensity:", forControlEvents: .ValueChanged)
        
        slider.minimumTrackTintColor = UIColor.whiteColor()
        slider.maximumTrackTintColor = UIColor.whiteColor()
        slider.thumbTintColor = UIColor(red:1, green:0.8, blue:0, alpha:1)
        let sliderThumbImage = UIImage(named: "slider_thumb_image", inBundle: bundle, compatibleWithTraitCollection: nil)
        slider.setThumbImage(sliderThumbImage, forState: .Normal)
        slider.setThumbImage(sliderThumbImage, forState: .Highlighted)
        
        return slider
    }()
    
    private var hideSliderTimer: NSTimer?
    
    private var filterSelectionViewConstraint: NSLayoutConstraint?
    public let filterSelectionController = IMGLYFilterSelectionController()
    
    public private(set) var cameraController: IMGLYCameraController?
    
    private var buttonsEnabled = true {
        didSet {
            flashButton.enabled = buttonsEnabled
            //switchCameraButton.enabled = buttonsEnabled
            //leaveCameraButton.enabled = buttonsEnabled
            cameraRollButton.enabled = buttonsEnabled
            takePhotoButton.enabled = buttonsEnabled
            filterSelectionController.view.userInteractionEnabled = buttonsEnabled
            filterSelectionButton.enabled = buttonsEnabled
        }
    }
    
    public var completionBlock: IMGLYCameraCompletionBlock?
    
    public var leavecompletionBlock: IMGLYLeaveCompletionBlock?
    
    // MARK: - UIViewController

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = NSBundle(forClass: self.dynamicType)
        
        navigationItem.title = NSLocalizedString("camera-view-controller.title", tableName: nil, bundle: bundle, value: "", comment: "")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "flash_auto", inBundle: bundle, compatibleWithTraitCollection: nil), style: UIBarButtonItemStyle.Done, target: self, action: "changeFlash:")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ww_cam_switch", inBundle: bundle, compatibleWithTraitCollection: nil), style: UIBarButtonItemStyle.Done, target: self, action: "switchCamera:")
            
        navigationController?.delegate = self
        
        view.backgroundColor = UIColor.blackColor()
        
        configureViewHierarchy()
        configureViewConstraints()
        configureFilterSelectionController()
        configureCameraController()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint where filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.beginAppearanceTransition(true, animated: animated)
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
      
        if let filterSelectionViewConstraint = filterSelectionViewConstraint where filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.endAppearanceTransition()
        }
        
        setLastImageFromRollAsPreview()
        cameraController?.startCamera()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController?.stopCamera()
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint where filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.beginAppearanceTransition(false, animated: animated)
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let filterSelectionViewConstraint = filterSelectionViewConstraint where filterSelectionViewConstraint.constant != 0 {
            filterSelectionController.endAppearanceTransition()
        }
    }
    
    public override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return false
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    public override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    public override func shouldAutorotate() -> Bool {
        return false
    }
    
    public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return .Portrait
    }

    // MARK: - Configuration
    
    private func configureViewHierarchy() {
        view.addSubview(topControlsView)
        view.addSubview(cameraPreviewContainer)
        view.addSubview(bottomControlsView)
        
        addChildViewController(filterSelectionController)
        filterSelectionController.didMoveToParentViewController(self)
        view.addSubview(filterSelectionController.view)
        
        topControlsView.addSubview(flashButton)
        //topControlsView.addSubview(switchCameraButton)
        //topControlsView.addSubview(leaveCameraButton)
        
        bottomControlsView.addSubview(cameraRollButton)
        bottomControlsView.addSubview(takePhotoButton)
        bottomControlsView.addSubview(filterSelectionButton)
        
        cameraPreviewContainer.addSubview(filterIntensitySlider)
    }
    
    private func configureViewConstraints() {
        let views: [NSObject : AnyObject] = [
            "topLayoutGuide" : topLayoutGuide,
            "topControlsView" : topControlsView,
            "cameraPreviewContainer" : cameraPreviewContainer,
            "bottomControlsView" : bottomControlsView,
            "filterSelectionView" : filterSelectionController.view,
            "flashButton" : flashButton,
            //"switchCameraButton" : switchCameraButton,
            //"leaveCameraButton" : leaveCameraButton,
            "cameraRollButton" : cameraRollButton,
            "takePhotoButton" : takePhotoButton,
            "filterSelectionButton" : filterSelectionButton,
            "filterIntensitySlider" : filterIntensitySlider
        ]
        
        let metrics: [NSObject : NSNumber] = [
            "topControlsViewHeight" : 44,
            "bottomControlsViewHeight" : 100,
            "filterSelectionViewHeight" : FilterSelectionViewHeight,
            "topControlMargin" : 20,
            "topControlMinWidth" : 44,
            "filterIntensitySliderLeftRightMargin" : 10
        ]
        
        configureSuperviewConstraintsWithMetrics(metrics, views: views)
        configureTopControlsConstraintsWithMetrics(metrics, views: views)
        configureCameraPreviewContainerConstraintsWithMetrics(metrics, views: views)
        configureBottomControlsConstraintsWithMetrics(metrics, views: views)
    }
    
    private func configureSuperviewConstraintsWithMetrics(metrics: [NSObject : NSNumber], views: [NSObject : AnyObject]) {
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[topControlsView]|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[cameraPreviewContainer]|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[bottomControlsView]|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[filterSelectionView]|", options: nil, metrics: nil, views: views))
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topLayoutGuide][topControlsView(==topControlsViewHeight)][cameraPreviewContainer][bottomControlsView(==bottomControlsViewHeight)][filterSelectionView(==filterSelectionViewHeight)]", options: nil, metrics: metrics, views: views))
        
        filterSelectionViewConstraint = NSLayoutConstraint(item: filterSelectionController.view, attribute: .Top, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
        view.addConstraint(filterSelectionViewConstraint!)
    }
    
    private func configureTopControlsConstraintsWithMetrics(metrics: [NSObject : NSNumber], views: [NSObject : AnyObject]) {
        //topControlsView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-(==topControlMargin)-[flashButton(>=topControlMinWidth)]-(>=topControlMargin)-[switchCameraButton(>=topControlMinWidth)]-(==topControlMargin)-|", options: nil, metrics: metrics, views: views))
        topControlsView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[flashButton]|", options: nil, metrics: nil, views: views))
        //topControlsView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[switchCameraButton]|", options: nil, metrics: nil, views: views))
        //topControlsView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[leaveCameraButton]|", options: nil, metrics: nil, views: views))
    }
    
    private func configureCameraPreviewContainerConstraintsWithMetrics(metrics: [NSObject : NSNumber], views: [NSObject : AnyObject]) {
        cameraPreviewContainer.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-(==filterIntensitySliderLeftRightMargin)-[filterIntensitySlider]-(==filterIntensitySliderLeftRightMargin)-|", options: nil, metrics: metrics, views: views))
        cameraPreviewContainer.addConstraint(NSLayoutConstraint(item: filterIntensitySlider, attribute: .Bottom, relatedBy: .Equal, toItem: cameraPreviewContainer, attribute: .Bottom, multiplier: 1, constant: -20))
    }
    
    private func configureBottomControlsConstraintsWithMetrics(metrics: [NSObject : NSNumber], views: [NSObject : AnyObject]) {
        // CameraRollButton
        cameraRollButton.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: BottomControlSize.width))
        cameraRollButton.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: BottomControlSize.height))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .CenterY, relatedBy: .Equal, toItem: bottomControlsView, attribute: .CenterY, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: cameraRollButton, attribute: .Left, relatedBy: .Equal, toItem: bottomControlsView, attribute: .Left, multiplier: 1, constant: 20))
        
        // TakePhotoButton
        bottomControlsView.addConstraint(NSLayoutConstraint(item: takePhotoButton, attribute: .CenterX, relatedBy: .Equal, toItem: bottomControlsView, attribute: .CenterX, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: takePhotoButton, attribute: .CenterY, relatedBy: .Equal, toItem: bottomControlsView, attribute: .CenterY, multiplier: 1, constant: 0))
        
        // FilterSelectionButton
        filterSelectionButton.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: BottomControlSize.width))
        filterSelectionButton.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: BottomControlSize.height))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: filterSelectionButton, attribute: .CenterY, relatedBy: .Equal, toItem: bottomControlsView, attribute: .CenterY, multiplier: 1, constant: 0))
        bottomControlsView.addConstraint(NSLayoutConstraint(item: bottomControlsView, attribute: .Right, relatedBy: .Equal, toItem: filterSelectionButton, attribute: .Right, multiplier: 1, constant: 20))
    }
    
    private func configureCameraController() {
        // Needed so that the framebuffer can bind to OpenGL ES
        view.layoutIfNeeded()
        
        cameraController = IMGLYCameraController(previewView: cameraPreviewContainer)
        cameraController!.delegate = self
        cameraController!.setup()
    }
    
    private func configureFilterSelectionController() {
        filterSelectionController.selectedBlock = { [weak self] filterType in
            if let cameraController = self?.cameraController where cameraController.effectFilter.filterType != filterType {
                cameraController.effectFilter = IMGLYInstanceFactory.effectFilterWithType(filterType)
                cameraController.effectFilter.inputIntensity = InitialFilterIntensity
                self?.filterIntensitySlider.value = InitialFilterIntensity
            }
            
            if filterType == .None {
                self?.hideSliderTimer?.invalidate()
                if let filterIntensitySlider = self?.filterIntensitySlider where filterIntensitySlider.alpha > 0 {
                    UIView.animateWithDuration(0.3) {
                        filterIntensitySlider.alpha = 0
                    }
                }
            } else {
                if let filterIntensitySlider = self?.filterIntensitySlider where filterIntensitySlider.alpha < 1 {
                    UIView.animateWithDuration(0.3) {
                        filterIntensitySlider.alpha = 1
                    }
                }
                
                self?.resetHideSliderTimer()
            }
        }
        
        filterSelectionController.activeFilterType = { [weak self] in
            if let cameraController = self?.cameraController {
                return cameraController.effectFilter.filterType
            } else {
                return .None
            }
        }
    }
    
    // MARK: - Helpers
    
    private func updateFlashButton() {
        if let cameraController = cameraController {
            flashButton.hidden = !cameraController.flashAvailable
            
            let bundle = NSBundle(forClass: self.dynamicType)
            
            switch(cameraController.flashMode) {
            case .Auto:
                self.flashButton.setImage(UIImage(named: "flash_auto", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
            case .On:
                self.flashButton.setImage(UIImage(named: "flash_on", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
            case .Off:
                self.flashButton.setImage(UIImage(named: "flash_off", inBundle: bundle, compatibleWithTraitCollection: nil), forState: UIControlState.Normal)
            }
        } else {
            flashButton.hidden = true
        }
    }
    
    private func resetHideSliderTimer() {
        hideSliderTimer?.invalidate()
        hideSliderTimer = NSTimer.scheduledTimerWithTimeInterval(ShowFilterIntensitySliderInterval, target: self, selector: "hideFilterIntensitySlider:", userInfo: nil, repeats: false)
    }
    
    private func showEditorNavigationControllerWithImage(image: UIImage?) {
        let editorViewController = IMGLYMainEditorViewController()
        editorViewController.highResolutionImage = image
        if let cameraController = cameraController {
            editorViewController.initialFilterType = cameraController.effectFilter.filterType
            editorViewController.initialFilterIntensity = cameraController.effectFilter.inputIntensity
        }
        editorViewController.completionBlock = editorCompletionBlock
        
        let navigationController = IMGLYNavigationController(rootViewController: editorViewController)
        navigationController.navigationBar.barStyle = .Black
        navigationController.navigationBar.translucent = false
        navigationController.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : UIColor.whiteColor() ]
        navigationController.navigationBar.tintColor = UIColor.whiteColor()
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    public func setLastImageFromRollAsPreview() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        if fetchResult.lastObject != nil {
            let lastAsset: PHAsset = fetchResult.lastObject as! PHAsset
            PHImageManager.defaultManager().requestImageForAsset(lastAsset, targetSize: CGSize(width: BottomControlSize.width * 2, height: BottomControlSize.height * 2), contentMode: PHImageContentMode.AspectFill, options: PHImageRequestOptions()) { (result, info) -> Void in
                //self.cameraRollButton.setImage(result, forState: UIControlState.Normal)
            }
        }
    }
    
    // MARK: - Targets
    
    @objc private func hideFilterIntensitySlider(timer: NSTimer?) {
        UIView.animateWithDuration(0.3) {
            self.filterIntensitySlider.alpha = 0
            self.hideSliderTimer = nil
        }
    }
    
    public func changeFlash(sender: UIButton?) {
        cameraController?.selectNextFlashMode()
    }
    
    public func switchCamera(sender: UIButton?) {
        cameraController?.toggleCameraPosition()
    }
    
    public func leaveCamera(sender: UIButton?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    public func showCameraRoll(sender: UIButton?) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeImage]
        imagePicker.allowsEditing = false
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    public func takePhoto(sender: UIButton?) {
        cameraController?.takePhoto { image, error in
            if error == nil {
                dispatch_async(dispatch_get_main_queue()) {
                    if let completionBlock = self.completionBlock {
                        completionBlock(image)
                    } else {
                        self.showEditorNavigationControllerWithImage(image)
                    }
                }
            }
        }
    }
    
    public func toggleFilters(sender: UIButton?) {
        if let filterSelectionViewConstraint = self.filterSelectionViewConstraint {
            let animationDuration = NSTimeInterval(0.6)
            let dampingFactor = CGFloat(0.6)
            
            if filterSelectionViewConstraint.constant == 0 {
                // Expand
                filterSelectionController.beginAppearanceTransition(true, animated: true)
                filterSelectionViewConstraint.constant = -1 * CGFloat(FilterSelectionViewHeight)
                UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: dampingFactor, initialSpringVelocity: 0, options: nil, animations: {
                    sender?.transform = CGAffineTransformIdentity
                    self.view.layoutIfNeeded()
                    }, completion: { finished in
                        self.filterSelectionController.endAppearanceTransition()
                })
            } else {
                // Close
                filterSelectionController.beginAppearanceTransition(false, animated: true)
                filterSelectionViewConstraint.constant = 0
                UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: dampingFactor, initialSpringVelocity: 0, options: nil, animations: {
                    sender?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                    self.view.layoutIfNeeded()
                    }, completion: { finished in
                        self.filterSelectionController.endAppearanceTransition()
                })
            }
        }
    }
    
    @objc private func changeIntensity(sender: UISlider?) {
        if let slider = sender {
            resetHideSliderTimer()
            cameraController?.effectFilter.inputIntensity = slider.value
        }
    }
    
    // MARK: - Completion
    
    private func editorCompletionBlock(result: IMGLYEditorResult, image: UIImage?) {
        
        
        if let image = image where result == .Done {
            UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
            leavecompletionBlock!(result,image)
            
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func image(image: UIImage, didFinishSavingWithError: NSError, contextInfo:UnsafePointer<Void>) {
        
        setLastImageFromRollAsPreview()
    }

}

extension IMGLYCameraViewController: IMGLYCameraControllerDelegate {
    public func cameraControllerDidStartCamera(cameraController: IMGLYCameraController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonsEnabled = true
        }
    }
    
    public func cameraControllerDidStopCamera(cameraController: IMGLYCameraController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonsEnabled = false
        }
    }
    
    public func cameraControllerDidStartStillImageCapture(cameraController: IMGLYCameraController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.takePhotoButton.imageView?.startAnimating()
            self.buttonsEnabled = false
        }
    }
    
    public func cameraControllerDidFailAuthorization(cameraController: IMGLYCameraController) {
        dispatch_async(dispatch_get_main_queue()) {
            let bundle = NSBundle(forClass: self.dynamicType)

            let alertController = UIAlertController(title: NSLocalizedString("camera-view-controller.camera-no-permission.title", tableName: nil, bundle: bundle, value: "", comment: ""), message: NSLocalizedString("camera-view-controller.camera-no-permission.message", tableName: nil, bundle: bundle, value: "", comment: ""), preferredStyle: .Alert)
            
            let settingsAction = UIAlertAction(title: NSLocalizedString("camera-view-controller.camera-no-permission.settings", tableName: nil, bundle: bundle, value: "", comment: ""), style: .Default) { _ in
                if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("camera-view-controller.camera-no-permission.cancel", tableName: nil, bundle: bundle, value: "", comment: ""), style: .Cancel, handler: nil)
            
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    public func cameraController(cameraController: IMGLYCameraController, didChangeToFlashMode flashMode: AVCaptureFlashMode) {
        dispatch_async(dispatch_get_main_queue()) {
            self.updateFlashButton()
        }
    }
    
    public func cameraControllerDidCompleteSetup(cameraController: IMGLYCameraController) {
        dispatch_async(dispatch_get_main_queue()) {
            self.updateFlashButton()
            //self.switchCameraButton.hidden = !cameraController.moreThanOneCameraPresent
            //self.leaveCameraButton.hidden = !cameraController.moreThanOneCameraPresent
        }
    }
    
    public func cameraController(cameraController: IMGLYCameraController, willSwitchToCameraPosition cameraPosition: AVCaptureDevicePosition) {
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonsEnabled = false
        }
    }
    
    public func cameraController(cameraController: IMGLYCameraController, didSwitchToCameraPosition cameraPosition: AVCaptureDevicePosition) {
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonsEnabled = true
            self.updateFlashButton()
        }
    }
}

extension IMGLYCameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
       
        self.dismissViewControllerAnimated(true, completion: {
            if let completionBlock = self.completionBlock {
                completionBlock(image)
            } else {
                self.showEditorNavigationControllerWithImage(image)
            }
        })
    }
    
    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
