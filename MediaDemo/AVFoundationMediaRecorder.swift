//
//  AVFoundationMediaRecorder.swift
//  MediaDemo
//
//  Created by David Yu on 10/9/15.
//  Copyright © 2015年 yanwei. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class AVFoundationMediaRecorder: UIViewController {
    
    var captureSession: AVCaptureSession!   //负责输入和输出设置之间的数据传递
    var captureDeviceInput: AVCaptureDeviceInput!    //负责从AVCaptureDevice获得输入数据
    var audioCaptureDeviceInput: AVCaptureDeviceInput!
    var captureMovieFileOutput: AVCaptureMovieFileOutput!     //视频输出流
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!     //相机拍摄预览图层
    var takeButton: UIButton!
    var movieView: UIView!
    var enableRotation: Bool = true
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var focusCursor: UIImageView!
//    var closure: (captureDevice: AVCaptureDevice) -> Void?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
        
        initSubViews()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initCapture()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func initSubViews() {
        movieView = UIView(frame: CGRectMake(0, (view.bounds.height-300)/2, view.bounds.width, 300))
        movieView.backgroundColor = UIColor.whiteColor()
        view.addSubview(movieView)
        movieView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "settingFocusCursor:"))
        
        focusCursor = UIImageView(frame: CGRectMake(movieView.bounds.width/2-movieView.bounds.height/4, movieView.bounds.height/4, movieView.bounds.height/2, movieView.bounds.height/2))
        focusCursor.image = UIImage(named: "camera_focus_red.png")
        movieView.addSubview(focusCursor)
        focusCursor.alpha = 0
        
        takeButton = UIButton(frame: CGRectMake((view.bounds.width-100)/2, view.bounds.height-100, 100, 50))
        takeButton.backgroundColor = UIColor.orangeColor()
        takeButton.setTitle("录制", forState: .Normal)
        takeButton.addTarget(self, action: "beginRecorderMovie:", forControlEvents: .TouchUpInside)
        view.addSubview(takeButton)
        
        let button = UIButton(frame: CGRectMake((view.bounds.width-100)/2, 84, 100, 30))
        button.setTitle("切换摄像头", forState: .Normal)
        button.backgroundColor = UIColor.orangeColor()
        button.addTarget(self, action: "changeCamrel", forControlEvents: .TouchUpInside)
        view.addSubview(button)
    }
    
    func initCapture() {
        //创建AVCaptureSession对象
        captureSession = AVCaptureSession()
        if captureSession.canSetSessionPreset(AVCaptureSessionPreset1280x720) {
            captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        }
        
        //获取使用的设备
        let captureDevice = getCameraDeviceWithPosition(.Back)
        if captureDevice.position != .Back {
            print("获取后置摄像头失败")
            return
        }
        
        //添加一个音频输入设备
        let audioCaptureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).first as! AVCaptureDevice
        
        //根据使用的设备初始化设备输出对象captureDeviceInput
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
        }catch {
            print("获取输出设备对象失败")
            return
        }
        
        //根据使用的设备初始化设备输出对象captureDeviceInput
        do {
            audioCaptureDeviceInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
        }catch {
            print("获取输出设备对象失败")
            return
        }
        
        //初始化设备输出对象，用于获得输出数据
        captureMovieFileOutput = AVCaptureMovieFileOutput()
        
        //将设备输入添加到会话中
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
            captureSession.addInput(audioCaptureDeviceInput)
            if let captureConnection = captureMovieFileOutput.connectionWithMediaType(AVMediaTypeVideo) {
                if captureConnection.supportsVideoStabilization {
                    captureConnection.preferredVideoStabilizationMode = .Auto
                }
            }
        }
        
        //将设备输入添加到会话中
        if captureSession.canAddOutput(captureMovieFileOutput) {
            captureSession.addOutput(captureMovieFileOutput)
        }
        
        //创建视频预览层，用于实时展示摄像头状态
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        let layer = movieView.layer
        layer.masksToBounds = true
        
        captureVideoPreviewLayer.frame = layer.bounds
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill       //填充模式
        
        //将视频预览层添加到界面中
        layer.insertSublayer(captureVideoPreviewLayer, below: focusCursor.layer)
//        layer.addSublayer(captureVideoPreviewLayer)
        
        //添加设备区域改变通知
        //注意添加区域改变捕获通知必须首先设置设备允许捕获
        addNotificationToCaptureDevice(captureDevice)
    }
    
    
    //录制按钮
    func beginRecorderMovie(button: UIButton) {
        //根据设备输出获得连接
        let captureConnection = captureMovieFileOutput.connectionWithMediaType(AVMediaTypeAudio)
        //根据连接获取到设备输出的数据
        if !captureMovieFileOutput.recording {
            button.setTitle("录制中", forState: .Normal)
            enableRotation = false
            //如果支持多任务则则开始多任务
            if UIDevice.currentDevice().multitaskingSupported {
                backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
            }
            //预览图层和视频方向保持一致
            captureConnection.videoOrientation = captureVideoPreviewLayer.connection.videoOrientation
            let outputFielPath = NSTemporaryDirectory() + "myMovie.mov"
            let url = NSURL(fileURLWithPath: outputFielPath)
            captureMovieFileOutput.startRecordingToOutputFileURL(url, recordingDelegate: self)
        }else {
            button.setTitle("录制", forState: .Normal)
            captureMovieFileOutput .stopRecording()
        }
    }
    
    //切换摄像头
    func changeCamrel() {
        let currentDevice = captureDeviceInput.device
        let currentPosition = currentDevice.position
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentDevice)
        var toChangePosition = AVCaptureDevicePosition.Front
        if currentPosition == AVCaptureDevicePosition.Unspecified || currentPosition == AVCaptureDevicePosition.Front {
            toChangePosition = AVCaptureDevicePosition.Back
        }
        let toChangeDevice = getCameraDeviceWithPosition(toChangePosition)
        addNotificationToCaptureDevice(toChangeDevice)
        //获得要调整的设备输入对象
        var toChangeDeviceInput: AVCaptureDeviceInput!
        do {
            toChangeDeviceInput = try AVCaptureDeviceInput(device: toChangeDevice)
        }catch {}
        //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
        captureSession.beginConfiguration()
        //移除原有输入对象
        captureSession.removeInput(captureDeviceInput)
        //添加新的输入对象
        if captureSession.canAddInput(toChangeDeviceInput) {
            captureSession.addInput(toChangeDeviceInput)
            captureDeviceInput = toChangeDeviceInput
        }
        
        //提交会话配置
        captureSession.commitConfiguration()
    }
    
    //手势获取聚焦光
    func settingFocusCursor(tap: UITapGestureRecognizer) {
        let point = tap.locationInView(tap.view)
        //将UI坐标转化为摄像头坐标
        let cameraPoint = captureVideoPreviewLayer.captureDevicePointOfInterestForPoint(point)
        setFocusCursorWithPoint(point)
        focusWithMode(.AutoFocus, exposureMode: .AutoExpose, point: cameraPoint)
    }
    
    //设置聚焦光标位置
    func setFocusCursorWithPoint(point: CGPoint) {
        focusCursor.center = point
        focusCursor.transform = CGAffineTransformMakeScale(1.2, 1.2)
        focusCursor.alpha = 1
        UIView.animateWithDuration(1, animations: { () -> Void in
            self.focusCursor.transform = CGAffineTransformMakeScale(1, 1)
            }) { (finish) -> Void in
                self.focusCursor.alpha = 0
        }
    }
    
    //设置聚焦点
    func focusWithMode(focusModel: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, point:CGPoint) {
        changeDeviceProperty { (captureDevice) -> Void in
            if captureDevice.isFocusModeSupported(focusModel) {
                captureDevice.focusMode = focusModel
            }
            if captureDevice.isExposureModeSupported(exposureMode) {
                captureDevice.exposureMode = exposureMode
            }
            captureDevice.exposurePointOfInterest = point
            captureDevice.focusPointOfInterest = point
        }
    }
    
    //给输入设备添加通知
    func addNotificationToCaptureDevice(captureDevice: AVCaptureDevice) {
        changeDeviceProperty { (captureDevice) -> Void in
            captureDevice.subjectAreaChangeMonitoringEnabled = true
        }
        //添加设备区域变化通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "areaChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: captureDevice)
    }
    
    
    //mark: 通知
    func areaChange(notification: NSNotification) {
        print("设备区域改变")
    }
    
    
    //改变设备属性的统一操作方法
    func changeDeviceProperty(closure :(captureDevice: AVCaptureDevice) -> Void) {
        let cDevice = captureDeviceInput.device
        do {
            try cDevice.lockForConfiguration()
            closure(captureDevice: cDevice)
            cDevice.unlockForConfiguration()
        }catch {
            print("设置设备属性过程发生错误")
        }
    }
    
    
    //获取指定位置的摄像头
    func getCameraDeviceWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let cameras = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for camera in cameras {
            if camera.position == position {
                return camera as! AVCaptureDevice
            }
        }
        return cameras.first as! AVCaptureDevice
    }
}


extension AVFoundationMediaRecorder: AVCaptureFileOutputRecordingDelegate {
    //视频输出代理
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("录制完成")
        enableRotation = true
        let lastBackgroundTaskIdentifier = backgroundTaskIdentifier
        backgroundTaskIdentifier = UIBackgroundTaskInvalid
        let assetsLibrary = ALAssetsLibrary()
        assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(outputFileURL) { (assetUrl, error) -> Void in
            if error != nil {
                print("保存视频到相簿过程中发生错误")
            }
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
            }catch {}
            if lastBackgroundTaskIdentifier != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(lastBackgroundTaskIdentifier)
            }
        }
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("开始录制")
    }
    
    //是否支持旋转
    override func shouldAutorotate() -> Bool {
        return enableRotation
    }
    
    //屏幕旋转时调整视频预览图层的方向
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let captureConnection = captureVideoPreviewLayer.connection
        switch toInterfaceOrientation {
            case .Portrait:
                captureConnection.videoOrientation = .Portrait
            case .PortraitUpsideDown:
                captureConnection.videoOrientation = .PortraitUpsideDown
            case .LandscapeLeft:
                captureConnection.videoOrientation = .LandscapeRight
            case .LandscapeRight:
                captureConnection.videoOrientation = .LandscapeLeft
            default:
                print("")
        }
    }
    
    //旋转后重新设置大小
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        captureVideoPreviewLayer.frame = movieView.bounds
    }
}

