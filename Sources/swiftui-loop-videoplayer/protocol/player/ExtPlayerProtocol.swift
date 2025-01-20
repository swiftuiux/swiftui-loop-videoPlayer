//
//  ExtPlayerProtocol.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A protocol defining the requirements for a looping video player.
///
/// Conforming types are expected to manage a video player that can loop content continuously,
/// handle errors, and notify a delegate of important events.
@available(iOS 14, macOS 11, tvOS 14, *)
@MainActor
public protocol ExtPlayerProtocol: AbstractPlayer, LayerMakerProtocol{
    
    #if canImport(UIKit)
        /// Provides a non-optional `CALayer` for use within UIKit environments.
        var layer: CALayer { get }
    #elseif canImport(AppKit)
        /// Provides an optional `CALayer` which can be set, and a property to indicate if the layer is wanted, for use within AppKit environments.
        var layer: CALayer? { get set }
        var wantsLayer: Bool { get set }
    #endif

    /// Provides a `AVPlayerLayer` specific to the player implementation, applicable across all platforms.
    var playerLayer: AVPlayerLayer? { get set }
    
    /// An optional NSKeyValueObservation to monitor errors encountered by the video player.
    /// This observer should be configured to detect and handle errors from the AVQueuePlayer,
    /// ensuring that all playback errors are managed and reported appropriately.
    var errorObserver: NSKeyValueObservation? { get set }
    
    /// An optional observer for monitoring changes to the player's `timeControlStatus` property.
    var timeControlObserver: NSKeyValueObservation? { get set }
    
    /// An optional observer for monitoring changes to the player's `currentItem` property.
    var currentItemObserver: NSKeyValueObservation? { get set }

    /// An optional observer for monitoring changes to the player's `volume` property.
    var volumeObserver: NSKeyValueObservation? { get set }
    
    /// Declare a variable to hold the time observer token outside the if statement
    var timeObserver: Any? { get set }

    /// Initializes a new player view with a video asset and custom settings.
    ///
    /// - Parameters:
    ///   - settings: The `VideoSettings` struct that includes all necessary configurations like gravity, loop, and mute.
    init(settings: VideoSettings)
    
    /// Sets up the necessary observers on the AVPlayerItem and AVQueuePlayer to monitor changes and errors.
    ///
    /// - Parameters:
    ///   - item: The AVPlayerItem to observe for status changes.
    ///   - player: The AVQueuePlayer to observe for errors.
    func setupObservers(for player: AVQueuePlayer)

}

internal extension ExtPlayerProtocol {
    
    /// Initializes a new player view with a video asset and custom settings.
    ///
    /// - Parameters:
    ///   - settings: The `VideoSettings` struct that includes all necessary configurations like gravity, loop, and mute.
    ///   - timePublishing: Optional `CMTime` that specifies a particular time for publishing or triggering an event.
    func setupPlayerComponents(
        settings: VideoSettings
    ) {
        
        guard let player else { return }
        
        configurePlayer(player, settings: settings)
        update(settings: settings)
        setupObservers(for: player)
    }
    
    /// Configures the provided AVQueuePlayer with specific properties for video playback.
    ///
    /// - Parameters:
    ///   - player: The AVQueuePlayer to be configured.
    ///   - settings: The `VideoSettings` struct that includes all necessary configurations like gravity, loop, and mute.
    func configurePlayer(
        _ player: AVQueuePlayer,
        settings: VideoSettings
    ) {
        
        player.isMuted = settings.mute
        if !settings.loop{
            player.actionAtItemEnd = .pause
        }
        
        configurePlayerLayer(player, settings)
        configureCompositeLayer(settings)
        configureTimePublishing(player, settings)
    }
    
    /// Configures the player layer for the specified video player using the provided settings.
    /// - Parameters:
    ///   - player: The `AVQueuePlayer` instance for which the player layer will be configured.
    ///   - settings: A `VideoSettings` object containing configuration details for the player layer.
    func configurePlayerLayer(_ player: AVQueuePlayer, _ settings: VideoSettings) {
        playerLayer?.player = player
        playerLayer?.videoGravity = settings.gravity

        #if canImport(UIKit)
        playerLayer?.backgroundColor = UIColor.clear.cgColor
        if let playerLayer{
            layer.addSublayer(playerLayer)
        }
        #elseif canImport(AppKit)
        playerLayer?.backgroundColor = NSColor.clear.cgColor
        let layer = CALayer()
        if let playerLayer{
            layer.addSublayer(playerLayer)
        }
        self.layer = layer
        self.wantsLayer = true
        #endif
    }
    
    /// Configures the time publishing observer for the specified video player.
    /// - Parameters:
    ///   - player: The `AVQueuePlayer` instance to which the time observer will be added.
    ///   - settings: A `VideoSettings` object containing the time publishing interval and related configuration.
    func configureTimePublishing(_ player: AVQueuePlayer, _ settings: VideoSettings) {
        if let timePublishing = settings.timePublishing{
            timeObserver = player.addPeriodicTimeObserver(forInterval: timePublishing, queue: .global()) { [weak self] time in
                guard let self = self else{ return }
                Task { @MainActor in
                    self.delegate?.didPassedTime(seconds: time.seconds)
                }
            }
        }
    }
    
    /// Configures the composite layer for the view based on the provided video settings.
    /// - Parameter settings: A `VideoSettings` object containing configuration details for the composite layer.
    func configureCompositeLayer(_ settings: VideoSettings) {
        
        guard settings.vector else { return }
        
        compositeLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        guard let compositeLayer else { return }
        
        #if canImport(UIKit)
        layer.addSublayer(compositeLayer)
        #elseif canImport(AppKit)
        self.layer?.addSublayer(compositeLayer)
        #endif
    }
    
    /// Updates the player with a new asset and applies the specified video settings.
    ///
    /// This method sets a new `AVURLAsset` for playback and configures it according to the provided settings.
    /// It can adjust options such as playback gravity, looping, and muting. If `doUpdate` is `true`, the player is
    /// updated immediately with the new asset. The method also provides an optional callback that is executed when
    /// the asset transitions to the `.readyToPlay` status, enabling additional actions to be performed once the
    /// player item is ready for playback.
    ///
    /// - Parameters:
    ///   - settings: A `VideoSettings` struct containing configurations such as playback gravity, looping behavior,
    ///               and whether the audio should be muted.
    func update(settings: VideoSettings) {
        
        if settings.isEqual(currentSettings){
            return
        }
        
        stop()
        
        currentSettings = settings
        
        guard let newItem = createPlayerItem(with: settings) else{
            return
        }
        
        insert(newItem)
        
        if settings.loop{
           loop()
        }

        if !settings.notAutoPlay{
            play()
        }
    }
        
    /// Sets up observers on the player item and the player to track their status and error states.
    ///
    /// - Parameters:
    ///   - item: The player item to observe.
    ///   - player: The player to observe.
    func setupObservers(for player: AVQueuePlayer) {
        errorObserver = player.observe(\.error, options: [.new]) { [weak self] player, _ in
            guard let error = player.error else { return }
            Task { @MainActor in
                self?.delegate?.didReceiveError(.remoteVideoError(error))
            }
        }
        
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] player, change in
            switch player.timeControlStatus {
            case .paused:
                // This could mean playback has stopped, but it's not specific to end of playback
                Task { @MainActor in
                    self?.delegate?.didPausePlayback()
                }
            case .waitingToPlayAtSpecifiedRate:
                // Player is waiting to play (e.g., buffering)
                Task { @MainActor in
                    self?.delegate?.isWaitingToPlay()
                }
            case .playing:
                // Player is currently playing
                Task { @MainActor in
                    self?.delegate?.didStartPlaying()
                }
            @unknown default:
                break
            }
        }
        
        currentItemObserver = player.observe(\.currentItem, options: [.new, .old]) { [weak self]  player, change in
            // Detecting when the current item is changed
            if let newItem = change.newValue as? AVPlayerItem {
                Task { @MainActor in
                    self?.delegate?.currentItemDidChange(to: newItem)
                }
            } else if change.newValue == nil {
                Task { @MainActor in
                    self?.delegate?.currentItemWasRemoved()
                }
            }
        }
        
        volumeObserver = player.observe(\.volume, options: [.new, .old]) { [weak self]  player, change in
            if let newVolume = change.newValue{
                Task { @MainActor in
                    self?.delegate?.volumeDidChange(to: newVolume)
                }
            }
        }
    }
    
    /// Clear observers
    func clearObservers(){
        
        errorObserver?.invalidate()
        errorObserver = nil
        
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        
        currentItemObserver?.invalidate()
        currentItemObserver = nil
        
        volumeObserver?.invalidate()
        volumeObserver = nil

        if let observerToken = timeObserver {
            player?.removeTimeObserver(observerToken)
            timeObserver = nil
        }
    }
    
    /// Add player layer
    func addPlayerLayer(){
        playerLayer = AVPlayerLayer()
    }
    
    /// Removes the player layer from its super layer.
    ///
    /// This method checks if the player layer is associated with a super layer and removes it to clean up resources
    /// and prevent potential retain cycles or unwanted video display when the player is no longer needed.
    func removePlayerLayer() {
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    /// Sets the playback command for the video player.
    /// - Parameter value: The `PlaybackCommand` to set. This can be one of the following:
    ///   - `play`: Command to play the video.
    ///   - `pause`: Command to pause the video.
    ///   - `seek(to:)`: Command to seek to a specific time in the video.
    ///   - `begin`: Command to position the video at the beginning.
    ///   - `end`: Command to position the video at the end.
    ///   - `mute`: Command to mute the video.
    ///   - `unmute`: Command to unmute the video.
    ///   - `volume`: Command to adjust the volume of the video playback.
    ///   - `subtitles`: Command to set subtitles to a specified language or turn them off.
    ///   - `playbackSpeed`: Command to adjust the playback speed of the video.
    ///   - `loop`: Command to enable looping of the video playback.
    ///   - `unloop`: Command to disable looping of the video playback.
    ///   - `brightness`: Command to adjust the brightness of the video playback.
    ///   - `contrast`: Command to adjust the contrast of the video playback.
    ///   - `filter`: Command to apply a specific Core Image filter to the video.
    ///   - `removeAllFilters`: Command to remove all applied filters from the video playback.
    ///   - `audioTrack`: Command to select a specific audio track based on language code.
    ///   - `vector`: Sets a vector graphic operation on the video player.
    ///   - `removeAllVectors`: Clears all vector graphics from the video player.
    func setCommand(_ value: PlaybackCommand) {
        switch value {
        case .play:
            play()
        case .pause:
            pause()
        case .seek(to: let time, play: let play):
            seek(to: time, play: play)
        case .begin:
            seekToStart()
        case .end:
            seekToEnd()
        case .mute:
            mute()
        case .unmute:
            unmute()
        case .volume(let volume):
            setVolume(volume)
        case .subtitles(let language):
            setSubtitles(to: language)
        case .playbackSpeed(let speed):
            setPlaybackSpeed(speed)
        case .loop:
            loop()
        case .unloop:
            unloop()
        case .brightness(let brightness):
            adjustBrightness(to: brightness)
        case .contrast(let contrast):
            adjustContrast(to: contrast)
        case .filter(let value, let clear):
            applyFilter(value, clear)
        case .removeAllFilters:
            removeAllFilters()
        case .audioTrack(let languageCode):
            selectAudioTrack(languageCode: languageCode)
        case .addVector(let builder, let clear):
            addVectorLayer(builder: builder, clear: clear)
        case .removeAllVectors:
            removeAllVectors()
        default : return
        }
    }
}
