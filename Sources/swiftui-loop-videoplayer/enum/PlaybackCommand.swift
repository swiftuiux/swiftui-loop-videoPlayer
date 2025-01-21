//
//  PlaybackCommand.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import AVFoundation
#if canImport(CoreImage)
import CoreImage
#endif

/// An enumeration of possible playback commands.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public enum PlaybackCommand: Equatable {
    
    /// The idle command to do nothing
    case idle
    
    /// Command to play the video.
    case play
    
    /// Command to pause the video.
    case pause
    
    /// Command to seek to a specific time in the video.
    ///
    /// This case allows seeking to a specified time position in the video and optionally starts playback immediately.
    ///
    /// - Parameters:
    ///   - time: The target time position in the video, specified in seconds.
    ///   - play: A Boolean value indicating whether playback should automatically resume after seeking.
    ///           Defaults to `true`.
    case seek(to: Double, play: Bool = true)
    
    /// Command to position the video at the beginning.
    case begin
    
    /// Command to position the video at the end.
    case end
    
    /// Command to mute the video.
    case mute
    
    /// Command to unmute the video.
    case unmute
    
    /// Command to adjust the volume of the video playback.
    /// - Parameter volume: A `Float` value between 0.0 (mute) and 1.0 (full volume). Values outside this range will be clamped.
    case volume(Float)
    
    /// Command to set subtitles for the video playback to a specified language or to turn them off.
    /// - Parameter language: The language code for the desired subtitles, pass `nil` to turn subtitles off.
    case subtitles(String?)
    
    /// Command to adjust the playback speed of the video.
    /// - Parameter speed: A `Float` value representing the playback speed. Valid range is typically from 0.5 to 2.0. Negative values will be clamped to 0.0.
    case playbackSpeed(Float)
    
    /// Command to enable looping of the video playback.
    /// Looping is assumed to be enabled by default.
    case loop
    
    /// Command to disable looping of the video playback.
    /// Only affects playback if looping is currently active.
    case unloop

    /// Command to adjust the brightness of the video playback.
    /// - Parameter brightness: A `Float` value typically ranging from -1.0 to 1.0.
    case brightness(Float)
    
    /// Command to adjust the contrast of the video playback.
    /// - Parameter contrast: A `Float` value typically ranging from 0.0 to 4.0.
    case contrast(Float)

    /// Command to apply a specific Core Image filter to the video.
    /// - Parameters:
    ///   - filter: A `CIFilter` object representing the filter to be applied.
    ///   - clear: A Boolean value indicating whether to clear the existing filter stack before applying this filter.
    /// This filter is added to the current stack of filters, allowing for multiple filters to be combined and applied sequentially, unless `clear` is true.
    case filter(CIFilter, clear: Bool = false)

    /// Command to remove all applied filters from the video playback.
    case removeAllFilters

    /// Represents a command to create and possibly clear existing vectors using a shape layer builder.
    /// - Parameters:
    ///   - builder: An instance conforming to `ShapeLayerBuilderProtocol` which will provide the shape layer.
    ///   - clear: A Boolean value that determines whether existing vector graphics should be cleared before applying the new vector. Defaults to `false`.
    case addVector(any ShapeLayerBuilderProtocol, clear: Bool = false)

    /// Represents a command to remove all vector graphics from the current view or context.
    case removeAllVectors
    
    /// Command to select a specific audio track based on language code.
    /// - Parameter languageCode: The language code (e.g., "en" for English) of the desired audio track.
    case audioTrack(languageCode: String)
    
    #if os(iOS)
    case startPiP
    
    case stopPiP
    #endif
    
    public static func == (lhs: PlaybackCommand, rhs: PlaybackCommand) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.play, .play), (.pause, .pause), (.begin, .begin), (.end, .end),
             (.mute, .mute), (.unmute, .unmute), (.loop, .loop), (.unloop, .unloop),
             (.removeAllFilters, .removeAllFilters), (.removeAllVectors, .removeAllVectors):
            return true
        #if os(iOS)
        case (.startPiP, .startPiP), (.stopPiP, .stopPiP):
            return true
        #endif
        case (.seek(let lhsTime, let lhsPlay), .seek(let rhsTime, let rhsPlay)):
            return lhsTime == rhsTime && lhsPlay == rhsPlay

        case (.volume(let lhsVolume), .volume(let rhsVolume)):
            return lhsVolume == rhsVolume

        case (.subtitles(let lhsLanguage), .subtitles(let rhsLanguage)):
            return lhsLanguage == rhsLanguage

        case (.playbackSpeed(let lhsSpeed), .playbackSpeed(let rhsSpeed)):
            return lhsSpeed == rhsSpeed

        case (.brightness(let lhsBrightness), .brightness(let rhsBrightness)):
            return lhsBrightness == rhsBrightness

        case (.contrast(let lhsContrast), .contrast(let rhsContrast)):
            return lhsContrast == rhsContrast

        case (.audioTrack(let lhsCode), .audioTrack(let rhsCode)):
            return lhsCode == rhsCode

        case (.filter(let lhsFilter, let lhsClear), .filter(let rhsFilter, let rhsClear)):
            return lhsFilter == rhsFilter && lhsClear == rhsClear
        case let (.addVector(lhsBuilder, lhsClear), .addVector(rhsBuilder, rhsClear)):
            return lhsBuilder.id == rhsBuilder.id && lhsClear == rhsClear
        default:
            return false
        }
    }
}
