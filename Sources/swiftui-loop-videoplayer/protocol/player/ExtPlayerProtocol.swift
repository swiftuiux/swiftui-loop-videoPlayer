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
@MainActor @preconcurrency
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
    var playerLayer: AVPlayerLayer { get }
    
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

    /// Responds to errors reported by the AVQueuePlayer.
    ///
    /// - Parameter player: The AVQueuePlayer that encountered an error.
    func handlePlayerError(_ player: AVPlayer)
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

        configurePlayerLayer(player, settings)
        configureCompositeLayer(settings)
        configureTimePublishing(player, settings)
    }
    
    /// Configures the player layer for the specified video player using the provided settings.
    /// - Parameters:
    ///   - player: The `AVQueuePlayer` instance for which the player layer will be configured.
    ///   - settings: A `VideoSettings` object containing configuration details for the player layer.
    func configurePlayerLayer(_ player: AVQueuePlayer, _ settings: VideoSettings) {
        playerLayer.player = player
        playerLayer.videoGravity = settings.gravity

        #if canImport(UIKit)
        playerLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(playerLayer)
        #elseif canImport(AppKit)
        playerLayer.backgroundColor = NSColor.clear.cgColor
        let layer = CALayer()
        layer.addSublayer(playerLayer)
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
                self.delegate?.didPassedTime(seconds: time.seconds)
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
    
    /// Updates the player with a new asset and applies specified video settings.
    /// Initializes playback or performs a specified action once the asset is ready.
    ///
    /// This method sets a new `AVURLAsset` to be played based on the provided settings.
    /// It can configure looping and muting options, and automatically starts playback if specified.
    /// A callback is executed when the asset transitions to the `.readyToPlay` status, allowing for
    /// further actions dependent on the readiness of the asset.
    ///
    /// - Parameters:
    ///   - settings: A `VideoSettings` struct containing configurations such as playback gravity,
    ///               whether to loop the content, and whether to mute the audio.
    ///   - asset: An optional `AVURLAsset` representing the new video content to be loaded. If nil,
    ///            the current asset continues playing with updated settings.
    ///   - callback: An optional closure executed when the asset reaches `.readyToPlay` status,
    ///               providing the new status as its parameter for handling additional setup or errors.
    func update(
        settings: VideoSettings,
        asset : AVURLAsset? = nil,
        callback: ((AVPlayerItem.Status) -> Void)? = nil
    ) {
        guard let player else { return }        
        
        guard let asset = asset ?? settings.getAssetIfDifferent(currentSettings) else {
            delegate?.didReceiveError(.sourceNotFound(settings.name))
            return }
        
        stop(player)
        
        currentSettings = settings
        
        let newItem = createPlayerItem(with: asset, settings: settings)
        
        insert(player, newItem)

        if settings.loop {
            loop()
        }
        
        // Observe status changes
        setupStateItemStatusObserver(newItem: newItem, callback: callback)

        if !settings.notAutoPlay {
            play()
        }
    }
    
    func insert(_ player: AVQueuePlayer,_ item : AVPlayerItem){
        player.insert(item, after: nil)
    }
    
    /// Stop and clean player
    func stop(_ player: AVQueuePlayer){
        
        player.pause()

        if !player.items().isEmpty {  // Cleaning
            unloop()
            clearPlayerQueue()
            removeAllFilters()
        }
    }
    
    /// Creates an `AVPlayerItem` with optional subtitle merging.
    /// - Parameters:
    ///   - asset: The main video asset.
    ///   - settings: A `VideoSettings` object containing subtitle configuration.
    /// - Returns: A new `AVPlayerItem` configured with the merged or original asset.
    func createPlayerItem(with asset: AVURLAsset, settings: VideoSettings) -> AVPlayerItem {
        // Attempt to retrieve the subtitle asset
        if let subtitleAsset = subtitlesAssetFor(settings),
           let mergedAsset = mergeAssetWithSubtitles(videoAsset: asset, subtitleAsset: subtitleAsset) {
            // Create and return a new `AVPlayerItem` using the merged asset
            return AVPlayerItem(asset: mergedAsset)
        } else {
            // Create and return a new `AVPlayerItem` using the original asset
            return AVPlayerItem(asset: asset)
        }
    }
    
    /// Sets up observers on the player item and the player to track their status and error states.
    ///
    /// - Parameters:
    ///   - item: The player item to observe.
    ///   - player: The player to observe.
    func setupObservers(for player: AVQueuePlayer) {
        errorObserver = player.observe(\.error, options: [.new]) { [weak self] player, _ in
            self?.handlePlayerError(player)
        }
        
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] player, change in
            switch player.timeControlStatus {
            case .paused:
                // This could mean playback has stopped, but it's not specific to end of playback
                self?.delegate?.didPausePlayback()
            case .waitingToPlayAtSpecifiedRate:
                // Player is waiting to play (e.g., buffering)
                self?.delegate?.isWaitingToPlay()
            case .playing:
                // Player is currently playing
                self?.delegate?.didStartPlaying()
            @unknown default:
                break
            }
        }
        
        currentItemObserver = player.observe(\.currentItem, options: [.new, .old]) { [weak self]  player, change in
            // Detecting when the current item is changed
            if let newItem = change.newValue as? AVPlayerItem {
                self?.delegate?.currentItemDidChange(to: newItem)
            } else if change.newValue == nil {
                self?.delegate?.currentItemWasRemoved()
            }
            
            self?.clearStatusObserver()
        }
        
        volumeObserver = player.observe(\.volume, options: [.new, .old]) { [weak self]  player, change in
            if let newVolume = change.newValue{
                self?.delegate?.volumeDidChange(to: newVolume)
            }
        }
    }
    
    /// Clears all items from the player's queue.
    func clearPlayerQueue() {
        player?.removeAllItems()
    }
    
    /// Removes observers for handling errors.
    ///
    /// This method ensures that the error observer is properly invalidated and the reference is cleared.
    /// It is important to call this method to prevent memory leaks and remove any unwanted side effects
    /// from obsolete observers.
    func removeObservers() {
        errorObserver?.invalidate()
        errorObserver = nil
    }

    /// Responds to errors reported by the AVPlayer.
    ///
    /// If an error is present, this method notifies the delegate of the encountered error,
    /// encapsulated within a `remoteVideoError`.
    /// - Parameter player: The AVPlayer that encountered an error to be evaluated.
    func handlePlayerError(_ player: AVPlayer) {
        guard let error = player.error else { return }
        delegate?.didReceiveError(.remoteVideoError(error))
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
        case .seek(to: let time):
            seek(to: time)
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
