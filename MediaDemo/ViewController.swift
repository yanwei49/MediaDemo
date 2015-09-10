//
//  ViewController.swift
//  MediaDemo
//
//  Created by David Yu on 10/9/15.
//  Copyright © 2015年 yanwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var dataSource: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ["AudioToolbox播放音效", "AVAudioRecorder录音", "AVAudioPlayer播放音频", "MPMusicPlayerController播放音乐库音乐", "MPMoviePlayerController播放音频", "MPMoviePlayerController播放视频", "AVPlayer自定义播放视频", "UIImagePickerController拍照", "AVFoundation拍照", "UIImagePickerController视频录制", "AVFoundation录制视频"]
        tableView.tableFooterView = UIView()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        cell?.textLabel!.text = dataSource[indexPath.row]
        
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        pushViewControllerWithIndex(indexPath.row)
    }
    
    func pushViewControllerWithIndex(index: Int) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Done, target: nil, action: nil)
        switch index {
        case 0:
            let vc = AudioToolbox()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 1:
            let vc = AVAudioRecorder()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 2:
            let vc = AVAudioPlayer()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 3:
            let vc = MPMusicLibrary()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 4:
            let vc = MPAVAudioPlayer()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 5:
            let vc = MPMediaPlayer()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 6:
            let vc = AVPlayer()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 7:
            let vc = UIImagePickerPhoto()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 8:
            let vc = AVFoundationPhoto()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 9:
            let vc = UIImagePickerMediaRecorder()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        case 10:
            let vc = AVFoundationMediaRecorder()
            vc.title = dataSource[index]
            navigationController?.showViewController(vc, sender: nil)
        default:
            break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

