//
//  LoopPlayerViewProtocol.swift
//
//
//  Created by Igor Shelopaev on 06.08.24.
//

import AVFoundation
import SwiftUI
import Combine

/// Protocol that defines the common functionalities and properties
/// for looping video players on different platforms.
@available(iOS 14, macOS 11, tvOS 14, *)
@MainActor @preconcurrency
public protocol LoopPlayerViewProtocol {
    
    #if canImport(UIKit)
    /// Typealias for the main view on iOS, using `UIView`.
    associatedtype View: UIView
    #elseif os(macOS)
    /// Typealias for the main view on macOS, using `NSView`.
    associatedtype View: NSView
    #else
    /// Typealias for a custom view type on platforms other than iOS and macOS.
    associatedtype View: CustomView
    #endif

    /// Typealias for the view used to display errors.
    associatedtype ErrorView

    #if canImport(UIKit)
    /// Typealias for the player view on iOS, conforming to `LoopingPlayerProtocol` and using `UIView`.
    associatedtype PlayerView: LoopingPlayerProtocol, UIView
    #elseif os(macOS)
    /// Typealias for the player view on macOS, conforming to `LoopingPlayerProtocol` and using `NSView`.
    associatedtype PlayerView: LoopingPlayerProtocol, NSView
    #else
    /// Typealias for a custom player view on other platforms, conforming to `LoopingPlayerProtocol`.
    associatedtype PlayerView: LoopingPlayerProtocol, CustomView
    #endif
    
    /// Settings for configuring the video player.
    var settings: VideoSettings { get set }
    
    /// Initializes a new instance of `LoopPlayerView`.
    /// - Parameters:
    ///   - settings: A binding to the video settings used by the player.
    ///   - command: A binding to the playback command that controls playback actions.
    ///   - timePublisher: A publisher that emits the current playback time as a `Double`.
    ///   - eventPublisher: A publisher that emits player events as `PlayerEvent` values.
    init(
        settings: Binding<VideoSettings>,
        command: Binding<PlaybackCommand>,
        timePublisher: PassthroughSubject<Double, Never>,
        eventPublisher: PassthroughSubject<PlayerEvent, Never>
    )
}

@available(iOS 14, macOS 11, tvOS 14, *)
public extension LoopPlayerViewProtocol{
    
    /// Updates the view by removing existing error messages and displaying a new one if an error is present.
    /// - Parameters:
    ///   - view: The view that needs to be updated with potential error messages.
    ///   - error: The optional error that might need to be displayed.
    @MainActor
    func updateView(_ view: View, error: VPErrors?) {
        
        makeErrorView(view, error: error)
    }
    
    /// Constructs an error view and adds it to the specified view if an error is present.
    /// - Parameters:
    ///   - view: The view to which the error message view will be added.
    ///   - error: The optional error which, if present, triggers the creation and addition of an error-specific view.
    @MainActor
    func makeErrorView(_ view: View, error: VPErrors?) {
        
        /// Check if error widget is off in settings
        guard settings.errorWidgetOff == false else{ return }
        
        if let error = error {
            let errorView = errorTpl(error, settings.errorColor, settings.errorFontSize)
            view.addSubview(errorView)
            activateFullScreenConstraints(for: errorView, in: view)
        }
    }
    
    /// Creates a player view for looping video content.
    /// - Parameters:
    ///   - context: The UIViewRepresentable context providing environment data and coordinator.
    ///   - asset: The AVURLAsset to be used for video playback.
    /// - Returns: A PlayerView instance conforming to LoopingPlayerProtocol.
    @MainActor
    func makePlayerView(
        _ container: View,
        asset: AVURLAsset?) -> PlayerView? {
        
        if let asset{
            let player = PlayerView(asset: asset, settings: settings)
            container.addSubview(player)
            activateFullScreenConstraints(for: player, in: container)
            return player
        }

        return nil
    }
}
