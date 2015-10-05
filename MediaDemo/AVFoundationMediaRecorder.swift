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

class AVFoundationMediaRecorder: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession!   //负责输入和输出设置之间的数据传递
    var captureDeviceInput: AVCaptureDeviceInput!    //负责从AVCaptureDevice获得输入数据
    var audioCaptureDeviceInput: AVCaptureDeviceInput!
    var captureMovieFileOutput: AVCaptureMovieFileOutput!     //视频输出流
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!     //相机拍摄预览图层
    var takeButton: UIButton!
    var movieView: UIView!
    var enableRotation: Bool = true
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
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
        layer.addSublayer(captureVideoPreviewLayer)
        
        //添加设备区域改变通知
        //注意添加区域改变捕获通知必须首先设置设备允许捕获
        addNotificationToCaptureDevice(captureDevice)
    }
    
    
    //录制按钮
    func beginRecorderMovie(button: UIButton) {
        button.setTitle("录制中", forState: .Normal)
        enableRotation = false
        //根据设备输出获得连接
        let captureConnection = captureMovieFileOutput.connectionWithMediaType(AVMediaTypeAudio)
        //根据连接获取到设备输出的数据
        if !captureMovieFileOutput.recording {
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
        do {
            let toChangeDeviceInput = try AVCaptureDeviceInput(device: toChangeDevice)
            //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
            captureSession.beginConfiguration()
            //移除原有输入对象
            captureSession.removeInput(captureDeviceInput)
            //添加新的输入对象
            if captureSession.canAddInput(toChangeDeviceInput) {
                captureSession.canAddInput(toChangeDeviceInput)
                captureDeviceInput = toChangeDeviceInput
            }
            
            //提交会话配置
            captureSession.commitConfiguration()
        }catch {}
        
    }
    
    
    //视频输出代理
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("开始录制")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("录制完成")
        enableRotation = true
        let lastBackgroundTaskIdentifier = backgroundTaskIdentifier
        backgroundTaskIdentifier = UIBackgroundTaskInvalid
        let assetsLibrary = ALAssetsLibrary()
        assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(fileURL) { (assetUrl, error) -> Void in
            if error != nil {
                print("保存视频到相簿过程中发生错误")
            }
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            }catch {}
            if lastBackgroundTaskIdentifier != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(lastBackgroundTaskIdentifier)
            }
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return enableRotation
    }
    
    
    //给输入设备添加通知
    func addNotificationToCaptureDevice(captureDevice: AVCaptureDevice) {
        changeDeviceProperty(captureDevice)
        //添加设备区域变化通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "areaChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: captureDevice)
    }
    
    
    //mark: 通知
    func areaChange(notification: NSNotification) {
        print("设备区域改变")
    }
    
    
    //改变设备属性的统一操作方法
    func changeDeviceProperty(captureDevice: AVCaptureDevice) {
        let cDevice = captureDeviceInput.device
        do {
            try cDevice.lockForConfiguration()
            cDevice.subjectAreaChangeMonitoringEnabled = true
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
