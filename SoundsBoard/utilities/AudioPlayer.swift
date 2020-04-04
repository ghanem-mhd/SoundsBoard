//
//  Player.swift
//  SoundsBoard
//
//  Created by Mohammad Ghanem on 28.03.20.
//  Copyright © 2020 Mohammed Ghannm. All rights reserved.
//

import AVFoundation

class AudioPlayer {
    static let sharedInstance = AudioPlayer()
    private var player: AVAudioPlayer?
    private var playedURL:URL?
    private var stopTimer = Timer()
    
    func play(soundFileName: String, startTime:TimeInterval? = nil, endTime:TimeInterval? = nil, checkPlayed: Bool = true, delegate: AVAudioPlayerDelegate? = nil){
        let url = SoundsFilesManger.getSoundURL(soundFileName)
        play(url: url, startTime: startTime, endTime:endTime,checkPlayed: checkPlayed, delegate: delegate)
    }
    
    func play(url: URL, startTime:TimeInterval? = nil, endTime:TimeInterval? = nil,checkPlayed: Bool = true, delegate: AVAudioPlayerDelegate? = nil) {
        if checkPlayed, let player = player, let playedURL = playedURL{
            if playedURL == url{
                if player.isPlaying{
                    player.pause()
                }else{
                    player.resume()
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
            playedURL = url
            player.delegate = delegate
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @objc func stop() {
        stopTimer.invalidate()
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
    //onError:(_ error:Error) -> Void
    //onError: { (Error) in }))
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