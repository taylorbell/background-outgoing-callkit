//
//  MediaManager.swift
//  RemoteEventSample
//
//  Created by Taylor Bell on 10/10/19.
//  Copyright © 2019 Taylor Bell. All rights reserved.
//

import Foundation
import AVFoundation
import CallKit
import MediaPlayer

class MediaManager : NSObject {
    
    let audioManager: AudioManager
    
    // AVFoundation
    var _player: AVAudioPlayer?
    var _recorder: AVAudioRecorder?
    
    // CallKit
    var _provider: CXProvider!
    var _controller: CXCallController!
    
    var isRecording: Bool {
        get { return _recorder != nil }
    }
    
    var isPlaying: Bool {
        get { return _player != nil }
    }
    
    var mode: MediaMode = .record {
        didSet { configureNowPlayingInfoCenter() }
    }
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        super.init()
        initializeCallKit()
    }
    
    private func initializeCallKit() {
        
        _controller = CXCallController()
        
        let config = CXProviderConfiguration(localizedName: "RemoteEvent Sample")
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic]
        config.supportsVideo = false
        
        if #available(iOS 11.0, *) {
            config.includesCallsInRecents = false
        }
        
        _provider = CXProvider(configuration: config)
        _provider.setDelegate(self, queue: nil)
        
    }
    
    /**
    Plays a sound file, in this case a beep, at a volume of 0. This is used to take over as the Now Playing app when the app enters the foreground to
    ensure we can receive remote control events.
     */
    func playSilentBeep() {
        
        guard !isPlaying else {
            return
        }
        
        if let filename = Bundle.main.path(forResource: "beep", ofType: "wav"), FileManager.default.fileExists(atPath: filename) {
            
            audioManager.startAudioSession(managed: false)
        
            do {
                _player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filename))
                _player?.delegate = self
                _player?.volume = 0
                _player?.play()
            } catch {}
            
        }
        
    }
    
    /**
    Start playback of the recording destination file, if one exists.
     */
    func startPlayback() {
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentsPath.appendingPathComponent("test_recording.m4a")
        
        if FileManager.default.fileExists(atPath: filename.path) {
            
            audioManager.startAudioSession(managed: false)
            
            do {
                
                _player = try AVAudioPlayer(contentsOf: filename)
                _player?.delegate = self
                _player?.volume = 1.0
                _player?.play()
                
                configureNowPlayingInfoCenter()
                
            } catch {}
            
        }
        
    }
    
    /**
     Stop playback if playback is currently active.
     */
    func stopPlayback() {
        
        _player?.stop()
        _player = nil
        
        configureNowPlayingInfoCenter()
        
    }
    
    /**
     Start recording by making a request to CallKit to start an outgoing call.
     */
    func startRecording() {
        requestStartCall()
    }
    
    /**
     Stop recording by making a request to CallKit to end an active outgoing call.
     */
    func stopRecording() {
        requestEndCall()
    }
    
    /**
     Configure the Now Playing Info Center to reflect the current media mode and playback or recording state.
     */
    func configureNowPlayingInfoCenter() {
        
        var nowPlayingInfo : [String : Any] = [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        switch mode {
            case .playback:
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Mode: Playback"
            case .record:
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Mode: Record"
        }
        
        if let _ = _recorder {
            nowPlayingInfo[MPMediaItemPropertyTitle] = "Recording..."
        } else if let _ = _player {
            nowPlayingInfo[MPMediaItemPropertyTitle] = "Playing..."
        } else {
            nowPlayingInfo[MPMediaItemPropertyTitle] = "Idle"
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
    }
    
}

extension MediaManager : CXProviderDelegate {
    
    func requestStartCall() {
        
        guard _controller.callObserver.calls.count == 0 else {
            return;
        }
        
        let uuid = UUID()
        let handle = CXHandle(type: .generic, value: "Test Channel")
        let action = CXStartCallAction(call: uuid, handle: handle)
        let transaction = CXTransaction(action: action)
        
        _controller.request(transaction) { (error) in
            
            if let error = error {
                print("Error requesting start call transaction: \(error)")
            }
            
        }
        
    }
    
    func requestEndCall() {
        
        guard let call = _controller.callObserver.calls.first else {
            return;
        }
        
        let action = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction(action: action)
        
        _controller.request(transaction) { (error) in
            
            if let error = error {
                print("Error requesting end call transaction: \(error)")
            }
            
        }
        
    }
    
    func notifyCallConnecting() {
        
        guard let call = _controller.callObserver.calls.first else {
            return;
        }
        
        _provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
        
    }
    
    func notifyCallConnected() {
        
        guard let call = _controller.callObserver.calls.first else {
            return;
        }
        
        _provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
        
    }
    
    func providerDidReset(_ provider: CXProvider) {}
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        
        audioManager.startAudioSession(managed: true)
        
        notifyCallConnecting()
        
        action.fulfill()
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        
        _recorder?.stop()
        
        action.fulfill()
        
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        
        //TODO: Start Recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = documentsPath.appendingPathComponent("test_recording.m4a")
        let settings = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            
            _recorder = try AVAudioRecorder(url: filename, settings: settings)
            _recorder?.delegate = self
            _recorder?.record()
            
            configureNowPlayingInfoCenter()
            
        } catch {}
        
        self.notifyCallConnected()
        
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        audioManager.endAudioSession()
    }
    
}

extension MediaManager : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        _recorder = nil
        
        configureNowPlayingInfoCenter()
        
    }
    
}

extension MediaManager : AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        _player = nil
        
        audioManager.endAudioSession()
        
        configureNowPlayingInfoCenter()
        
    }
    
}
