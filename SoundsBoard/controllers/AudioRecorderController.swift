//
//  test.swift
//  SoundsBoard
//
//  Created by Mohammed Ghannm on 09.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//
/*
import UIKit
import SnapKit
import AVFoundation
import SwiftySound

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
    
    
    var timeTimer:Timer?
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    var soundGeneratedName: String?
    var milliseconds: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        setUpViews()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Recorder"
        self.view.backgroundColor = .white
        
        //audioRecorderDelegate = presentingViewController as! AudioRecorderViewControllerDelegate;
        
        soundGeneratedName = SoundsFilesManger.generateSoundName()
    
        do {
            try recorder = AVAudioRecorder(url: SoundsFilesManger.getSoundURL(soundGeneratedName!), settings: recordingSettings)
        } catch let error {
            print(error)
        }
    
    }
    
    func setUpViews(){
        
        self.navigationItem.rightBarButtonItem = doneButton

        self.view.addSubview(timeLabel)
        timeLabel.text = "00:00"
        timeLabel.font = timeLabel.font.withSize(25)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .center
        timeLabel.snp.makeConstraints{ (make) -> Void in
            make.width.equalTo(150)
            
            make.center.equalTo(self.view.snp.center)
        }

        
        let bottomView = UIView()
        bottomView.backgroundColor = .lightGray
        self.view.addSubview(bottomView)

        bottomView.snp.makeConstraints{ (make) -> Void in
            make.height.equalTo(100)
            make.width.equalTo(self.view.snp.width)
            make.bottom.equalTo(self.view.snp.bottom)
        }
        
        self.view.addSubview(recordButton)
        recordButton.delegate = self
        recordButton.snp.makeConstraints{ (make) -> Void in
            make.width.height.equalTo(75)
            make.centerX.equalTo(bottomView.snp.centerX)
            make.centerY.equalTo(bottomView.snp.centerY)
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
        
        //setUpPlayerView()
    }
    
    
    func setUpPlayerView(){
        
        self.view.addSubview(playerView)
        
        playerView.axis             = NSLayoutConstraint.Axis.horizontal
        playerView.distribution     = UIStackView.Distribution.equalCentering
        playerView.alignment        = UIStackView.Alignment.center
        
        playerView.addArrangedSubview(playButton)
        playerView.addArrangedSubview(pauseButton)
        playerView.addArrangedSubview(stopButton)
        playerView.backgroundColor = .yellow
        
        playerView.snp.makeConstraints{ (make) -> Void in
            make.bottom.equalTo(self.view.snp.bottom)
            make.width.equalTo(self.view.frame.width / 2)
            make.centerX.equalTo(self.view.snp.centerX)
        }
        
        if let playIcon = UIImage(named:"round_play_arrow_black_48pt"){
            playButton.setImage(playIcon, for: .normal)
            playButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }

        if let pauseIcon = UIImage(named: "round_pause_black_48pt"){
            pauseButton.setImage(pauseIcon , for: .normal)
            pauseButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        if let stopIcon = UIImage(named: "round_stop_black_48pt"){
            stopButton.setImage(stopIcon , for: .normal)
            stopButton.snp.makeConstraints{ (make) -> Void in
                make.width.height.equalTo(50)
            }
        }
        
        playButton.addTarget(self, action: #selector(onPlayButtonClicked), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(onPauseButtonClicked), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(onStopButtonClicked), for: .touchUpInside)
    }
    
    @objc func onPlayButtonClicked(_ sender: UIButton){
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            if (player == nil){
                player = try AVAudioPlayer(contentsOf: SoundsFilesManger.getSoundURL(soundGeneratedName!))
            }
            player?.play()
        } catch let error {
            print(error)
        }
    }
    
    @objc func onPauseButtonClicked(_ sender: UIButton){
        if let activePlayer = player {
            if (activePlayer.isPlaying) {
                activePlayer.pause()
            }
        }
    }
    
    @objc func onStopButtonClicked(_ sender: UIButton){
        if let activePlayer = player {
            if (activePlayer.isPlaying) {
                activePlayer.stop()
            }
        }
    }
    
    func longPressRecordButtonDidStartLongPress(_ button: LongPressRecordButton) {
        if let r = recorder{
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            milliseconds = 0
            timeLabel.text = "00:00.00"
            timeTimer = Timer.scheduledTimer(timeInterval: 0.0167, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
            r.prepareToRecord()
            r.deleteRecording()
            r.record()
            player = nil
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
    
    let recordingSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                    AVSampleRateKey: NSNumber(value: 44100),
                    AVNumberOfChannelsKey: NSNumber(value: 2)]
}
*/
