//
//  test.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 09.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import NVActivityIndicatorView


protocol AudioRecorderViewControllerDelegate: class {
    func audioRecorderFinished(_ generatedName: String)
}


class AudioRecorderController: UIViewController,LongPressRecordButtonDelegate,AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    weak var audioRecorderDelegate: AudioRecorderViewControllerDelegate?
    
    lazy var recordButton   = LongPressRecordButton()
    lazy var timeLabel      = UILabel()
    lazy var doneButton     = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
    lazy var playerView     = UIStackView()
    lazy var playButton     = UIButton()
    lazy var stopButton     = UIButton()
    lazy var pauseButton    = UIButton()
    lazy var animation      = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    let recordindAnimationType:NVActivityIndicatorType = .ballClipRotateMultiple
    let playingAnimationType:NVActivityIndicatorType = .audioEqualizer
    
    var timeTimer:Timer?
    var recorder: AVAudioRecorder?
    var soundFileName: String?
    var milliseconds: Int = 0
    
    var isRecored = false
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.rightBarButtonItem = doneButton
        setUpViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Recorder"
        self.view.backgroundColor = .white
        do {
            soundFileName = SoundsFilesManger.generateSoundFileName()
            try recorder = AVAudioRecorder(url: SoundsFilesManger.getSoundURL(soundFileName!), settings: recordingSettings)
        } catch let error {
            print(error)
        }
    }
    
    func longPressRecordButtonDidStartLongPress(_ button: LongPressRecordButton) {
        animation.stopAnimating()
        AudioPlayer.sharedInstance.stop()
        animation.type = recordindAnimationType
        animation.startAnimating()
        if let r = recorder{
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.record)
            milliseconds = 0
            timeLabel.text = "00:00"
            timeTimer = Timer.scheduledTimer(timeInterval: 0.0167, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
            r.prepareToRecord()
            r.deleteRecording()
            r.record()
        }
    }
    
    func longPressRecordButtonDidStopLongPress(_ button: LongPressRecordButton) {
        animation.stopAnimating()
        if let r = recorder{
            r.stop()
            timeTimer?.invalidate()
            isRecored = true
        }
    }
    
    @objc func doneButtonClicked(_ sender: Any){
        if !isRecored{
            return
        }
        if let soundName = soundFileName, let delegate = audioRecorderDelegate{
            delegate.audioRecorderFinished(soundName)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func updateTimeLabel(timer: Timer) {
        milliseconds += 1
        let sec = (milliseconds / 60) % 60
        let min = milliseconds / 3600
        self.timeLabel.text =  String(format: "%02d:%02d", min, sec)
    }
    
    func setUpViews(){
        animation.color = .systemBlue
        self.view.addSubview(animation)
        animation.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.view.snp.centerY).offset(-32)
            make.width.equalTo(self.view.snp.width).offset(-64)
            make.centerX.equalTo(self.view.snp.centerX)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(32)
        }
        
        let label = UILabel()
        self.view.addSubview(label)
        label.textAlignment = NSTextAlignment.center
        label.text = "Press and hold to record the sound!"
        label.textColor = .lightGray
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.light)
        label.snp.makeConstraints{ (make) -> Void in
            make.height.equalTo(100)
            make.width.equalTo(self.view.snp.width)
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY).offset(50)
        }
        
        
        self.view.addSubview(timeLabel)
        timeLabel.text = "00:00"
        timeLabel.textAlignment = .center
        timeLabel.textColor = .lightGray
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.light)
        timeLabel.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(self.view.snp.width)
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(label.snp.centerY).offset(32)
        }
        
        
        self.view.addSubview(recordButton)
        recordButton.delegate = self
        recordButton.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(75)
            make.centerX.equalTo(self.view.snp.centerX)
            make.bottom.equalTo(self.view.snp.bottom).offset(-16)
        }
        
        if let micIcon = UIImage(named:"round_mic_black_48pt"){
            let micIconImageView = UIImageView(image:micIcon)
            micIconImageView.tintColor = .white
            self.view.addSubview(micIconImageView)
            micIconImageView.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(30)
                make.center.equalTo(self.recordButton.snp.center)
            }
        }
        
        if let playIcon = UIImage(named:"round_play_arrow_black_48pt"){
            self.view.addSubview(playButton)
            playButton.setImage(playIcon, for: .normal)
            playButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(75)
                make.centerY.equalTo(self.recordButton.snp.centerY)
                make.centerX.equalTo(self.recordButton.snp.centerX).offset(self.view.frame.width / 4)
            }
        }
        
        if let stopIcon = UIImage(named: "round_stop_black_48pt"){
            self.view.addSubview(stopButton)
            stopButton.setImage(stopIcon , for: .normal)
            stopButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(75)
                make.centerY.equalTo(self.recordButton.snp.centerY)
                make.centerX.equalTo(self.recordButton.snp.centerX).offset(-self.view.frame.width / 4)
            }
        }
        
        playButton.addTarget(self, action: #selector(onPlayButtonClicked), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopButtonClicked), for: .touchUpInside)
    }
    
    @objc func onPlayButtonClicked(_ sender: UIButton){
        if !isRecored{
            return
        }
        if let soundName = soundFileName{
            animation.type = .audioEqualizer
            animation.startAnimating()
            AudioPlayer.sharedInstance.play(soundFileName: soundName, checkPlayed: false, delegate: self)
        }
    }
    
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        animation.stopAnimating()
        AudioPlayer.sharedInstance.stop()
        timeLabel.text = "00:00"
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        animation.stopAnimating()
    }
    
    let recordingSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                             AVSampleRateKey: NSNumber(value: 44100),
                             AVNumberOfChannelsKey: NSNumber(value: 2)]
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParent {
            if let r = recorder{
                //r.deleteRecording()
            }
        }
        AudioPlayer.sharedInstance.stop()
    }
}
