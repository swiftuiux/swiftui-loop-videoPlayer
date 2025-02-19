//
//  Setting.swift
//  
//
//  Created by Igor Shelopaev on 07.07.2023.
//

import Foundation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

/// Configuration settings for a loop video player.
/// These settings control various playback and UI behaviors.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public enum Setting: Equatable, SettingsConvertible {

    /// Converts the current setting into an array containing itself.
    /// - Returns: An array with a single instance of `Setting`.
    public func asSettings() -> [Setting] {
        [self]
    }

    /// Event filters to monitor specific player events.
    case events([PlayerEventFilter]?)

    /// Enables a vector layer for overlaying vector graphics.
    case vector

    /// Enables looping of the video playback.
    case loop

    /// Mutes the video.
    case mute

    /// Prevents automatic playback after initialization.
    case notAutoPlay

    /// Specifies the file name of the video.
    case name(String)

    /// Specifies the file extension of the video.
    case ext(String)

    /// Sets subtitles for the video.
    case subtitles(String)

    /// Enables Picture-in-Picture (PiP) mode support.
    case pictureInPicture

    /// Defines the interval at which the player's current time should be published.
    case timePublishing(CMTime)

    /// Sets the video gravity (e.g., aspect fit, aspect fill).
    case gravity(AVLayerVideoGravity = .resizeAspect)

    /// Retrieves the name of the current case.
    var caseName: String {
        Mirror(reflecting: self).children.first?.label ?? "\(self)"
    }

    /// Retrieves the associated value of the case, if any.
    var associatedValue: Any? {
        guard let firstChild = Mirror(reflecting: self).children.first else {
            return nil
        }
        return firstChild.value
    }
}
