//
//  PlayerEvents.swift
//
//
//  Created by Igor Shelopaev on 15.08.24.
//

import Foundation
import AVFoundation

/// An enumeration representing various events that can occur within a media player.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public enum PlayerEvent: Equatable {
    
    /// Represents an end seek action within the player.
    /// - Parameters:
    ///   - Bool: Indicates whether the seek was successful.
    ///   - currentTime: The time (in seconds) to which the player is seeking.
    case seek(Bool, currentTime: Double)
    
    /// Indicates that the player's playback is currently paused.
    ///
    /// This state occurs when the player has been manually paused by the user or programmatically
    /// through a method like `pause()`. The player is not playing any content while in this state.
    case paused

    /// Indicates that the player is currently waiting to play at the specified rate.
    ///
    /// This state generally occurs when the player is buffering or waiting for sufficient data
    /// to continue playback. It can also occur if the playback rate is temporarily reduced to zero
    /// due to external factors, such as network conditions or system resource limitations.
    case waitingToPlayAtSpecifiedRate

    /// Indicates that the player is actively playing content.
    ///
    /// This state occurs when the player is currently playing video or audio content at the
    /// specified playback rate. This is the active state where media is being rendered to the user.
    case playing
    
    /// Indicates that the player has switched to a new item.
    ///
    /// This event is triggered when the player's `currentItem` changes to a new `AVPlayerItem`.
    /// - Parameter newItem: The new `AVPlayerItem` that the player has switched to.
    case currentItemChanged(newItem: AVPlayerItem?)
    
    /// Indicates that the player has removed the current item.
    ///
    /// This event is triggered when the player's `currentItem` is set to `nil`, meaning that there
    /// is no media item currently loaded in the player.
    case currentItemRemoved
    
    /// Indicates that the player's volume has changed.
    ///
    /// This event is triggered when the player's `volume` property is adjusted.
    /// - Parameter newVolume: The new volume level, ranging from 0.0 (muted) to 1.0 (full volume).
    case volumeChanged(newVolume: Float)
    
    /// Represents a case where a specific VPErrors type error is encountered.
    ///
    /// - Parameter VPErrors: The error from the VPErrors enum associated with this case.
    case error(VPErrors)
    
    /// Event triggered when the bounds of the video player change.
    /// - Parameter CGRect: The new bounds of the video player.
    case boundsChanged(CGRect)

    /// Event triggered when Picture-in-Picture (PiP) mode starts.
    case startedPiP

    /// Event triggered when Picture-in-Picture (PiP) mode stops.
    case stoppedPiP
}

extension PlayerEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .seek(let success, _):
            return success ? "SeekSuccess" : "SeekFail"
        case .paused:
            return "Paused"
        case .waitingToPlayAtSpecifiedRate:
            return "Waiting"
        case .playing:
            return "Playing"
        case .currentItemChanged(_):
            return "ItemChanged"
        case .currentItemRemoved:
            return "ItemRemoved"
        case .volumeChanged(_):
            return "VolumeChanged"
        case .error(let e):
            return "\(e.description)"
        case .boundsChanged(let bounds):
            return "Bounds changed \(bounds)"
        case .startedPiP:
            return "Started PiP"
        case .stoppedPiP:
            return "Stopped PiP"
        }
    }
}
