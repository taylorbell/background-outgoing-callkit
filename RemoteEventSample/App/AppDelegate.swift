//
//  AppDelegate.swift
//  RemoteEventSample
//
//  Created by Taylor Bell on 10/10/19.
//  Copyright © 2019 Taylor Bell. All rights reserved.
//

import UIKit
import MediaPlayer
import CallKit

enum MediaMode {
    case playback
    case record
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var _audioManager: AudioManager!
    var _mediaManager: MediaManager!
    var _mediaMode: MediaMode = .record

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        _audioManager = AudioManager()
        _mediaManager = MediaManager(audioManager: _audioManager)
        
        registerRemoteCommandEventHandlers()
        
        // Activate the audio session and play a silent beep to become the Now Playing app
        _mediaManager.playSilentBeep()
        
        if AVAudioSession.sharedInstance().recordPermission != .granted {
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                // Since this is a quick test app we're going to assume the user will grant permission
            }
        }
        
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {
        if !_audioManager.isActive {
            _audioManager.startAudioSession(managed: false)
            _mediaManager.playSilentBeep()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

    func registerRemoteCommandEventHandlers() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.stopCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(onPlayCommand))
        commandCenter.stopCommand.addTarget(self, action: #selector(onStopCommand))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(onNextCommand))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(onPreviousCommand))
        
    }
    
    @objc func onPlayCommand() -> MPRemoteCommandHandlerStatus {
        startMedia()
        return .success
        
    }
    
    @objc func onStopCommand() -> MPRemoteCommandHandlerStatus {
        stopMedia()
        return .success
    }
    
    @objc func onNextCommand() -> MPRemoteCommandHandlerStatus {
        toggleMediaMode()
        return .success
    }
    
    @objc func onPreviousCommand() -> MPRemoteCommandHandlerStatus {
        toggleMediaMode()
        return .success
    }
    
    private func toggleMediaMode() {
        
        switch _mediaMode {
            case .playback:
                _mediaMode = .record
            case .record:
                _mediaMode = .playback
        }
        
        _mediaManager.mode = _mediaMode
        
    }
    
    private func startMedia() {
        
        switch _mediaMode {
            case .playback:
                _mediaManager.startPlayback()
            case .record:
                _mediaManager.startRecording()
        }
        
    }
    
    private func stopMedia() {
        
        switch _mediaMode {
            case .playback:
                _mediaManager.stopPlayback()
            case .record:
                _mediaManager.stopRecording()
        }
        
    }

}

