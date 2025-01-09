//
//  LoopingPlayerProtocol.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import SwiftUI

#if canImport(AVKit)
import AVKit
#endif

#if canImport(UIKit)
import UIKit

@MainActor @preconcurrency
internal class LoopingPlayerUIView: UIView, LoopingPlayerProtocol {   
    
    /// This property holds an instance of `VideoSettings`
    internal var currentSettings : VideoSettings?
    
    /// `filters` is an array that stores CIFilter objects used to apply different image processing effects
    internal var filters: [CIFilter] = []

    /// `brightness` represents the adjustment level for the brightness of the video content.
    internal var brightness: Float = 0

    /// `contrast` indicates the level of contrast adjustment for the video content.
    internal var contrast: Float = 1
    
    /// A CALayer instance used for composing content, accessible only within the module.
    internal let compositeLayer = CALayer()
    
    /// The AVPlayerLayer that displays the video content.
    internal let playerLayer = AVPlayerLayer()
    
    /// The looper responsible for continuous video playback.
    internal var playerLooper: AVPlayerLooper?
    
    /// The queue player that plays the video items.
    internal var player: AVQueuePlayer?
    
    /// Declare a variable to hold the time observer token outside the if statement
    internal var timeObserver: Any?
    
    /// Observer for errors from the AVQueuePlayer.
    internal var errorObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `timeControlStatus` property.
    internal var timeControlObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `currentItem` property.
    internal var currentItemObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `volume` property.
    ///
    /// This property holds an instance of `NSKeyValueObservation`, which observes the `volume`
    /// of an `AVPlayer`.
    internal var volumeObserver: NSKeyValueObservation?
    
    /// Observes the status property of the new player item.
    internal var statusObserver: NSKeyValueObservation?
    
    /// The delegate to be notified about errors encountered by the player.
    weak var delegate: PlayerDelegateProtocol?

    /// Initializes a new player view with a video asset and custom settings.
    ///
    /// - Parameters:
    ///   - asset: The `AVURLAsset` used for video playback.
    ///   - settings: The `VideoSettings` struct that includes all necessary configurations like gravity, loop, and mute.
    ///   - timePublishing: Optional `CMTime` that specifies a particular time for publishing or triggering an event.
    required init(asset: AVURLAsset, settings: VideoSettings, timePublishing: CMTime?){
        super.init(frame: .zero)
        setupPlayerComponents(
            asset: asset, settings: settings, timePublishing : timePublishing
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Lays out subviews and adjusts the frame of the player layer to match the view's bounds.
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    /// Cleans up resources and observers associated with the player.
    ///
    /// This method invalidates the status and error observers to prevent memory leaks,
    /// pauses the player, and clears out player-related references to assist in clean deinitialization.
    deinit {
        cleanUp(
            player: &player,
            playerLooper: &playerLooper,
            errorObserver: &errorObserver,
            timeControlObserver : &timeControlObserver,
            currentItemObserver: &currentItemObserver,
            volumeObserver: &volumeObserver,
            statusObserver: &statusObserver,
            timeObserver: &timeObserver)
    }
}
#endif
