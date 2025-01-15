//
//  LoopPlayerMultiPlatform.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import SwiftUI
import Combine

#if canImport(AVKit)
import AVKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
internal struct LoopPlayerMultiPlatform: LoopPlayerViewProtocol {
        
    #if canImport(UIKit)
    typealias View = UIView
    
    typealias ErrorView = ErrorMsgViewIOS
    
    typealias PlayerView = LoopingPlayerUIView
    #elseif canImport(AppKit)
    typealias View = NSView
    
    typealias ErrorView = ErrorMsgViewMacOS
    
    typealias PlayerView = LoopingPlayerNSView
    #endif
    
    /// A publisher that emits the current playback time as a `Double`.
    private let timePublisher: PassthroughSubject<Double, Never>

    /// A publisher that emits player events as `PlayerEvent` values.
    private let eventPublisher: PassthroughSubject<PlayerEvent, Never>
    
    /// Command for the player view
    @Binding public var command : PlaybackCommand
    
    /// Settings for the player view
    @Binding public var settings: VideoSettings
       
    /// State to store any error that occurs
    @State private var error: VPErrors?
    
    var asset : AVURLAsset?{
        assetFor(settings)
    }

    /// Initializes a new instance of `ExtPlayerView`.
    /// - Parameters:
    ///   - settings: A binding to the video settings used by the player.
    ///   - command: A binding to the playback command that controls playback actions.
    ///   - timePublisher: A publisher that emits the current playback time as a `Double`.
    ///   - eventPublisher: A publisher that emits player events as `PlayerEvent` values.
    init(
        settings: Binding<VideoSettings>, 
        command: Binding<PlaybackCommand>,
        timePublisher : PassthroughSubject<Double, Never>,
        eventPublisher : PassthroughSubject<PlayerEvent, Never>
    ) {
        self.timePublisher = timePublisher
        self.eventPublisher = eventPublisher
        self._settings = settings
        self._command = command
        let settings = settings.wrappedValue
        let asset =  assetFor(settings)
        let e = detectError(settings: settings, asset: asset)
        if let e {
            self._error = State(initialValue: e)
        }
    }

    
    /// Creates a coordinator that handles error-related updates and interactions between the SwiftUI view and its underlying model.
    /// - Returns: An instance of PlayerErrorCoordinator that can be used to manage error states and communicate between the view and model.
    func makeCoordinator() -> PlayerCoordinator {
        PlayerCoordinator($error, timePublisher: timePublisher, eventPublisher: eventPublisher)
    }
}

#if canImport(UIKit)
extension LoopPlayerMultiPlatform: UIViewRepresentable{
    /// Creates the container view with the player view and error view if needed
    /// - Parameter context: The context for the view
    /// - Returns: A configured UIView
    @MainActor func makeUIView(context: Context) -> UIView {
       let container = UIView()
   
       if let player: PlayerView = makePlayerView(
            container){
           player.delegate = context.coordinator
       }
        
        makeErrorView(container, error: error)

        return container
    }
    
    /// Updates the container view, removing any existing error views and adding a new one if needed
    /// - Parameters:
    ///   - uiView: The UIView to update
    ///   - context: The context for the view
    @MainActor func updateUIView(_ uiView: UIView, context: Context) {
        let player = uiView.findFirstSubview(ofType: PlayerView.self)
       
        if let player{
            if let asset = settings.getAssetIfDifferent(player.currentSettings) {
                player.update(asset: asset, settings: settings)
            }
            
            // Check if command changed before applying it
            if context.coordinator.getLastCommand != command {
                player.setCommand(command)
                context.coordinator.setLastCommand(command) // Update the last command in the coordinator
            }
        }
        
        if let e = error {
            eventPublisher
                .send(.error(e))
        }
        
        updateView(uiView, error: error)
    }
}
#endif

#if canImport(AppKit)
extension LoopPlayerMultiPlatform: NSViewRepresentable{
    /// Creates the NSView for the representable component. It initializes the view, configures it with a player if available, and adds an error view if necessary.
    /// - Parameter context: The context containing environment and state information used during view creation.
    /// - Returns: A fully configured NSView containing both the media player and potentially an error message display.
    @MainActor func makeNSView(context: Context) -> NSView {
        let container = NSView()
        
        if let player: PlayerView = makePlayerView(
             container,
             asset: asset){
            player.delegate = context.coordinator
        }
         

        makeErrorView(container, error: error)
         
        return container
    }
    
    /// Updates the specified NSView during the view's lifecycle in response to state changes.
    /// - Parameters:
    ///   - nsView: The NSView that needs updating.
    ///   - context: The context containing environment and state information used during the view update.
    @MainActor func updateNSView(_ nsView: NSView, context: Context) {
        let player = nsView.findFirstSubview(ofType: PlayerView.self)
        if let player {
            if let asset = settings.getAssetIfDifferent(player.currentSettings){
                player.update(asset: asset, settings: settings)
            }
            // Check if command changed before applying it
            if context.coordinator.getLastCommand != command {
                player.setCommand(command)
                context.coordinator.setLastCommand(command) // Update the last command in the coordinator
            }
            
        }
        
        if let e = error {
            eventPublisher
                .send(.error(e))
        }
        
        updateView(nsView, error: error)
    }
}
#endif
