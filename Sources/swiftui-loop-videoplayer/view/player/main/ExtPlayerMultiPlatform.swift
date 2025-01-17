//
//  ExtPlayerMultiPlatform.swift
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
internal struct ExtPlayerMultiPlatform: ExtPlayerViewProtocol {
        
    #if canImport(UIKit)
    typealias View = UIView
    
    typealias PlayerView = ExtPlayerUIView
    #elseif canImport(AppKit)
    typealias View = NSView    
    
    typealias PlayerView = ExtPlayerNSView
    #endif
    
    /// A publisher that emits the current playback time as a `Double`.
    private let timePublisher: PassthroughSubject<Double, Never>

    /// A publisher that emits player events as `PlayerEvent` values.
    private let eventPublisher: PassthroughSubject<PlayerEvent, Never>
    
    /// Command for the player view
    @Binding public var command : PlaybackCommand
    
    /// Settings for the player view
    @Binding public var settings: VideoSettings
    
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
    }
    /// Creates a coordinator that handles error-related updates and interactions between the SwiftUI view and its underlying model.
    /// - Returns: An instance of PlayerErrorCoordinator that can be used to manage error states and communicate between the view and model.
    func makeCoordinator() -> PlayerCoordinator {
        PlayerCoordinator(timePublisher: timePublisher, eventPublisher: eventPublisher)
    }
}

#if canImport(UIKit)
extension ExtPlayerMultiPlatform: UIViewRepresentable{
    /// Creates the container view with the player view and error view if needed
    /// - Parameter context: The context for the view
    /// - Returns: A configured UIView
    func makeUIView(context: Context) -> UIView {
       let container = UIView()
   
       if let player: PlayerView = makePlayerView(container){
           player.delegate = context.coordinator
       }

       return container
    }
    
    /// Updates the container view, removing any existing error views and adding a new one if needed
    /// - Parameters:
    ///   - uiView: The UIView to update
    ///   - context: The context for the view
    func updateUIView(_ uiView: UIView, context: Context) {
        let player = uiView.findFirstSubview(ofType: PlayerView.self)
       
        if let player{
            player.update(settings: settings)
            
            // Check if command changed before applying it
            if context.coordinator.getLastCommand != command {
                player.setCommand(command)
                context.coordinator.setLastCommand(command) // Update the last command in the coordinator
            }
        }        
    }
    
    /// Called by SwiftUI to dismantle the UIView when the associated SwiftUI view is removed from the view hierarchy.
    ///
    /// - Parameters:
    ///   - uiView: The UIView instance being dismantled.
    ///   - coordinator: The coordinator instance that manages interactions between SwiftUI and the UIView.
    static func dismantleUIView(_ uiView: UIView, coordinator: PlayerCoordinator) {
        // Called by SwiftUI when this view is removed from the hierarchy
        let player = uiView.findFirstSubview(ofType: PlayerView.self)
        if let player{
            player.onDisappear()
        }
    }
}
#endif

#if canImport(AppKit)
extension ExtPlayerMultiPlatform: NSViewRepresentable{
    /// Creates the NSView for the representable component. It initializes the view, configures it with a player if available, and adds an error view if necessary.
    /// - Parameter context: The context containing environment and state information used during view creation.
    /// - Returns: A fully configured NSView containing both the media player and potentially an error message display.
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        
        if let player: PlayerView = makePlayerView(container){
            player.delegate = context.coordinator
        }
         
        return container
    }
    
    /// Updates the specified NSView during the view's lifecycle in response to state changes.
    /// - Parameters:
    ///   - nsView: The NSView that needs updating.
    ///   - context: The context containing environment and state information used during the view update.
    func updateNSView(_ nsView: NSView, context: Context) {
        let player = nsView.findFirstSubview(ofType: PlayerView.self)
        if let player {
            
            player.update(settings: settings)
            
            // Check if command changed before applying it
            if context.coordinator.getLastCommand != command {
                player.setCommand(command)
                context.coordinator.setLastCommand(command) // Update the last command in the coordinator
            }
        }
    }
    
    /// Called by SwiftUI to dismantle the NSView when the associated SwiftUI view is removed from the view hierarchy.
    ///
    /// - Parameters:
    ///   - uiView: The NSView instance being dismantled.
    ///   - coordinator: The coordinator instance that manages interactions between SwiftUI and the NSView.
    static func dismantleUIView(_ uiView: NSView, coordinator: PlayerCoordinator) {
        // Called by SwiftUI when this view is removed from the hierarchy
        let player = uiView.findFirstSubview(ofType: PlayerView.self)
        if let player{
            player.onDisappear()
        }
    }
}
#endif
