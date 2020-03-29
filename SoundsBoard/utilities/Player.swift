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
    
    func play(url: URL, checkPlayed: Bool = true, delegate: AVAudioPlayerDelegate? = nil) {
        if checkPlayed, let player = player, let playedURL = playedURL{
            if playedURL == url{
                player.resume()
                return
            }else{
                player.stop()
            }
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.play()
            playedURL = url
            player.delegate = delegate
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stop() {
        if let p = player{
            p.stop()
            p.delegate = nil
         }
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
}
