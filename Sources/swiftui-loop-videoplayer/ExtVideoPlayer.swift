//
//  PlayerView.swift
//
//
//  Created by Igor Shelopaev on 10.02.2023.
//

import SwiftUI
import Combine
#if canImport(AVKit)
import AVKit
#endif

/// Player view for running a video in loop
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct ExtVideoPlayer: View{
    
    /// Set of settings for video the player
    @Binding public var settings: VideoSettings
    
    /// Binding to a playback command that controls playback actions
    @Binding public var command: PlaybackCommand
    
    /// The current playback time, represented as a Double.
    @State private var currentTime: Double = 0.0
    
    /// The current state of the player event,
    @State private var playerEvent: [PlayerEvent] = []

    /// A publisher that emits the current playback time as a `Double`. It is initialized privately within the view.
    @State private var timePublisher = PassthroughSubject<Double, Never>()

    /// A publisher that emits player events as `PlayerEvent` values. It is initialized privately within the view.
    @State private var eventPublisher = PassthroughSubject<PlayerEvent, Never>()
    
    // MARK: - Life cycle
    
    /// Player initializer
    /// - Parameters:
    ///   - fileName: The name of the video file.
    ///   - ext: The file extension, with a default value of "mp4".
    ///   - gravity: The video gravity setting, with a default value of `.resizeAspect`.
    ///   - timePublishing: An optional `CMTime` value for time publishing, with a default value of 1 second.
    ///   - command: A binding to the playback command, with a default value of `.play`.
    public init(
        fileName: String,
        ext: String = "mp4",
        gravity: AVLayerVideoGravity = .resizeAspect,
        timePublishing : CMTime? = CMTime(seconds: 1, preferredTimescale: 600),
        command : Binding<PlaybackCommand> = .constant(.play)
    ) {
        self._command = command

        func description(@SettingsBuilder content: () -> [Setting]) -> [Setting] {
          return content()
        }
        
        let settings: VideoSettings = VideoSettings {
            SourceName(fileName)
            Ext(ext)
            Gravity(gravity)
            if let timePublishing{
                timePublishing
           }
        }
        
        _settings = .constant(settings)
    }
    
    /// Player initializer in a declarative way
    /// - Parameters:
    ///   - settings: Set of settings
    ///   - command: A binding to control playback actions
    public init(
        _ settings: () -> VideoSettings,
        command: Binding<PlaybackCommand> = .constant(.play)
    ) {

        self._command = command
        _settings = .constant(settings())
    }
    
    /// Player initializer in a declarative way
    /// - Parameters:
    ///   - settings: A binding to the set of settings for the video player
    ///   - command: A binding to control playback actions
    public init(
        settings: Binding<VideoSettings>,
        command: Binding<PlaybackCommand> = .constant(.play)
    ) {
        self._settings = settings
        self._command = command
    }
    
    // MARK: - API
       
   /// The body property defines the view hierarchy for the user interface.
   public var body: some View {
       ExtPlayerMultiPlatform(
            settings: $settings,
            command: $command,
            timePublisher: timePublisher,
            eventPublisher: eventPublisher
       )
       .onReceive(timePublisher.receive(on: DispatchQueue.main), perform: { time in
           currentTime = time
       })
       .onReceive(eventPublisher.collect(.byTime(DispatchQueue.main, .seconds(1))), perform: { event in
           playerEvent = filterEvents(with: settings, for: event)
       })
       .preference(key: CurrentTimePreferenceKey.self, value: currentTime)
       .preference(key: PlayerEventPreferenceKey.self, value: playerEvent)
   }
}

// MARK: - Fileprivate

/// Filters a list of `PlayerEvent` instances based on the provided `VideoSettings`.
///
/// - Parameters:
///   - settings: The video settings containing event filters.
///   - events: The list of events to be filtered.
/// - Returns: A filtered list of `PlayerEvent` that match at least one filter in `settings`.
fileprivate func filterEvents(with settings: VideoSettings, for events: [PlayerEvent]) -> [PlayerEvent] {
    let filters = settings.events  // `[PlayerEventFilter]`
    
    // If no filters are provided, return an empty array.
    guard let filters else {
        return []
    }
    
    guard !filters.isEmpty else{
        return events
    }
    
    // Keep each `PlayerEvent` only if it matches *at least* one filter in `filters`.
    return events.filter { event in
        filters.contains(event)
    }
}
