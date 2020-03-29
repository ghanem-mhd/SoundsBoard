//
//  Player.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 28.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import AVFoundation

protocol AudioPlayerCustomDelegate: class {
    func currentTimePlayed(currentTime: TimeInterval)
}


class AudioPlayer {
    static let sharedInstance = AudioPlayer()
    private var player: AVAudioPlayer?
    private var playedURL:URL?
    private var stopTimer = Timer()
    private var playTimer = Timer()
    
    func play(soundFileName: String, startTime:TimeInterval? = nil, endTime:TimeInterval? = nil,checkPlayed: Bool = true, delegate: AVAudioPlayerDelegate? = nil, customDelegate: AudioPlayerCustomDelegate? = nil){
        let url = SoundsFilesManger.getSoundURL(soundFileName)
        play(url: url, startTime: startTime, endTime:endTime,checkPlayed: checkPlayed, delegate: delegate, customDelegate:customDelegate)
    }
    
    func play(url: URL, startTime:TimeInterval? = nil, endTime:TimeInterval? = nil,checkPlayed: Bool = true, delegate: AVAudioPlayerDelegate? = nil, customDelegate: AudioPlayerCustomDelegate? = nil) {
        if checkPlayed, let player = player, let playedURL = playedURL{
            if playedURL == url{
                player.resume()
                if let cd = customDelegate{
                    setUpTimer(customDelegate: cd)
                }
                return
            }else{
                stop()
            }
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            if let st = startTime{
                player.currentTime = st
            }
            if let et = endTime{
                stopTimer.invalidate()
                stopTimer = Timer.scheduledTimer(timeInterval: et, target: self, selector: #selector(AudioPlayer.stop), userInfo: nil, repeats: false)
            }
            player.play()
            if let cd = customDelegate{
                setUpTimer(customDelegate: cd)
            }
            playedURL = url
            player.delegate = delegate
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func setUpTimer(customDelegate: AudioPlayerCustomDelegate){
        if let p = player{
            playTimer.invalidate()
            playTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                customDelegate.currentTimePlayed(currentTime: p.currentTime)
            }
        }
    }
    
    @objc func stop() {
        stopTimer.invalidate()
        playTimer.invalidate()
        if let p = player{
            p.stop()
            p.delegate = nil
        }
        player = nil
    }
    
    func pause() {
        player?.pause()
    }
    
    func getDuration() -> TimeInterval{
        if let p = player{
            return p.duration
        }
        return TimeInterval(exactly: 0)!
    }
    
    func getCurrentTime() -> TimeInterval{
        if let p = player{
            return p.currentTime
        }
        return TimeInterval(exactly: 0)!
    }
    
    func getDuration(soundFileName: String) ->TimeInterval{
        let url = SoundsFilesManger.getSoundURL(soundFileName)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch let error {
            print(error.localizedDescription)
        }
        return TimeInterval(exactly: 0)!
    }
    
    func getFormatedTime(timeInSeconds: Int)->String{
        return String(format: "%02d:%02d", (timeInSeconds) / 60, (timeInSeconds) % 60)
    }
    
    func getFormatedTime(timeInSeconds: Float)->String{
        return getFormatedTime(timeInSeconds: (Int)(timeInSeconds))
    }
}
