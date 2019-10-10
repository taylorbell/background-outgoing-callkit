//
//  AudioManager.swift
//  RemoteEventSample
//
//  Created by Taylor Bell on 10/10/19.
//  Copyright © 2019 Taylor Bell. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager {
    
    private var _active = false
    private var _managed = false
    
    var isActive: Bool {
        get { return _active }
    }
    
    /**
     Configure the audio session.
     - Parameter managed: Indicates if another source, in this case CallKit, is managing the audio session
     */
    func startAudioSession(managed: Bool) {
        
        guard !_active else {
            return
        }
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            
            try session.setCategory(AVAudioSession.Category.playAndRecord,
                                    mode: AVAudioSession.Mode.voiceChat,
                                    options: AVAudioSession.CategoryOptions(arrayLiteral: [AVAudioSession.CategoryOptions.defaultToSpeaker]))
            
            if (!managed) {
                try session.setActive(true, options: [])
            }
            
        } catch {}
        
        _active = true
        _managed = managed
        
    }
    
    /**
     Deactivate the audio session.
     */
    func endAudioSession() {
        
        guard !_managed else {
            _managed = false
            return
        }
        
        if _active {
            
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setActive(false, options: [])
            } catch {}
            
        }
        
        _active = false
        
    }
    
}
