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
import SwiftySound
import AudioKit
import AudioKitUI

protocol AudioRecorderViewControllerDelegate: class {
    func audioRecorderViewControllerDismissed(soundGeneratedName name: String)
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
    
    lazy var plotView = AKNodeOutputPlot()
    
    
    var timeTimer:Timer?
    var recorder: AVAudioRecorder?
    //var player: AVAudioPlayer?
    var soundGeneratedName: String?
    var milliseconds: Int = 0
    
    enum State {
        case readyToRecord
        case recording
        case readyToPlay
        case playing
    }
    

    var player =  AKPlayer()
    var mic    = AKMicrophone()
    var state = State.readyToRecord
    
    override func viewWillAppear(_ animated: Bool) {
        setUpViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Recorder"
        self.view.backgroundColor = .white
        
        
        player.completionHandler = playingEnded
        self.plotView.node = mic
        AudioKit.output = player
        try? AudioKit.start()
        
        soundGeneratedName = SoundsFilesManger.generateSoundName()
        do {
            try recorder = AVAudioRecorder(url: SoundsFilesManger.getSoundURL(soundGeneratedName!), settings: recordingSettings)
        } catch let error {
            print(error)
        }
    

    }
    
    func setUpViews(){
        
        self.navigationItem.rightBarButtonItem = doneButton
        

        
        setUpPlayerView()
    }
    
    
    func longPressRecordButtonDidStartLongPress(_ button: LongPressRecordButton) {
        plotView.node = mic
        if let r = recorder{
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            milliseconds = 0
            timeLabel.text = "00:00.00"
            timeTimer = Timer.scheduledTimer(timeInterval: 0.0167, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
            r.prepareToRecord()
            r.deleteRecording()
            r.record()
        }
    }
    
    func longPressRecordButtonDidStopLongPress(_ button: LongPressRecordButton) {
        if let r = recorder{
            r.stop()
            print("Stop")
            timeTimer?.invalidate()
        }
    }
    
    @objc func doneButtonClicked(_ sender: Any){
        
    }
    
    @objc func buttonClicked(_ sender: UIButton){
        
    }
    
    @objc func updateTimeLabel(timer: Timer) {
        milliseconds += 1
        let sec = (milliseconds / 60) % 60
        let min = milliseconds / 3600
        timeLabel.text = NSString(format: "%02d:%02d", min, sec) as String
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        try! AudioKit.stop()
    }
    
    func setUpPlayerView(){
        let label = UILabel()
        self.view.addSubview(label)
        label.textAlignment = NSTextAlignment.center
        label.text = "Press and hold to recrod the sound!"
        label.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(self.view.snp.width)
            make.centerX.equalTo(self.view.snp.centerX)
            make.centerY.equalTo(self.view.snp.centerY).offset(-100)
        }
        
        self.view.addSubview(plotView)
        plotView.snp.makeConstraints{ (make) -> Void in
            make.height.equalTo(50)
            make.width.equalTo(self.view.snp.width)
            make.center.equalTo(self.view.snp.center)
        }
        

        self.view.addSubview(timeLabel)
        timeLabel.text = "00:00:00"
        timeLabel.font = timeLabel.font.withSize(25)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .center
        timeLabel.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(150)
            make.top.equalTo(self.plotView.snp.bottom)
            make.centerX.equalTo(self.view.snp.centerX)
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
        state = .playing
        do {
            try AKSettings.setSession(category: .playback)
            try player.load(url: SoundsFilesManger.getSoundURL(soundGeneratedName!))
            plotView.node = player
            player.play()
        }catch let error {
            print(error)
        }

    }
    
    func playingEnded() {
        self.plotView.node = self.mic
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        state = .readyToRecord
        player.stop()
        plotView.node = mic
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
    }
    
    let recordingSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                    AVSampleRateKey: NSNumber(value: 44100),
                    AVNumberOfChannelsKey: NSNumber(value: 2)]
}
