//
//  ExtPlayerNSView.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import SwiftUI

#if canImport(AVKit)
import AVKit
#endif

#if canImport(AppKit)
import AppKit

/// A NSView subclass that loops video using AVFoundation on macOS.
/// This class handles the initialization and management of a looping video player with customizable video gravity.
@MainActor
internal class ExtPlayerNSView: NSView, ExtPlayerProtocol {
    
    /// This property holds an instance of `VideoSettings`
    internal var currentSettings : VideoSettings?
    
    /// `filters` is an array that stores CIFilter objects used to apply different image processing effects
    internal var filters: [CIFilter] = []

    /// `brightness` represents the adjustment level for the brightness of the video content.
    internal var brightness: Float = 0

    /// `contrast` indicates the level of contrast adjustment for the video content.
    internal var contrast: Float = 1
    
    /// A CALayer instance used for composing content, accessible only within the module.
    internal var compositeLayer : CALayer?
    
    /// The AVPlayerLayer that displays the video content.
    internal var playerLayer : AVPlayerLayer?
    
    /// The looper responsible for continuous video playback.
    internal var playerLooper: AVPlayerLooper?
    
    /// The queue player that plays the video items.
    internal var player: AVQueuePlayer? = AVQueuePlayer(items: [])
    
    /// Declare a variable to hold the time observer token outside the if statement
    internal var timeObserver: Any?
    
    /// Observer for errors from the AVQueuePlayer.
    internal var errorObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `timeControlStatus` property.
    internal var timeControlObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `currentItem` property.
    internal var currentItemObserver: NSKeyValueObservation?
    
    /// Item status observer
    internal var itemStatusObserver: NSKeyValueObservation?
    
    /// An optional observer for monitoring changes to the player's `volume` property.
    ///
    /// This property holds an instance of `NSKeyValueObservation`, which observes the `volume`
    /// of an `AVPlayer`.
    internal var volumeObserver: NSKeyValueObservation?
    
    /// The delegate to be notified about errors encountered by the player.
    weak var delegate: PlayerDelegateProtocol?

    /// Initializes a new player view with a video asset and specified configurations.
    ///
    /// - Parameters:
    ///   - asset: The `AVURLAsset` for video playback.
    ///   - settings: The `VideoSettings` struct that includes all necessary configurations like gravity, loop, and mute.
    required init(settings: VideoSettings) {
        
        player = AVQueuePlayer(items: [])
        
        super.init(frame: .zero)
        self.wantsLayer = true
        
        addPlayerLayer()
        addCompositeLayer(settings)
        
        setupPlayerComponents(settings: settings)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Lays out subviews and adjusts the frame of the player layer to match the view's bounds.
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
        // Update the composite layer (and sublayers)
        layoutCompositeLayer()
    }
    
    /// Updates the composite layer and all its sublayers' frames.
    public func layoutCompositeLayer() {
        guard let compositeLayer = compositeLayer else { return }
        
        // Update the composite layer's frame to match the parent
        compositeLayer.frame = bounds
        
        // Adjust each sublayer's frame (if they should fill the entire composite layer)
        compositeLayer.sublayers?.forEach { sublayer in
            sublayer.frame = compositeLayer.bounds
        }
        
        delegate?.boundsDidChange(to: bounds)
    }


    func onDisappear(){
        // First, clear all observers to prevent memory leaks
        clearObservers()
        
        // Stop the player to ensure it's not playing any media
        stop()
        
        // Remove visual layers to clean up the UI components
        removePlayerLayer()
        removeCompositeLayer()
        
        // Finally, release player and delegate references to free up memory
        player = nil
        delegate = nil
        
        // Log the cleanup process for debugging purposes
        #if DEBUG
        print("Player deinitialized and resources cleaned up.")
        #endif
    }
}
#endif
