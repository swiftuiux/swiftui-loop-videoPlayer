//
//  PlayerEventFilter.swift
//  swiftui-loop-videoplayer
//
//  Created by Igor  on 12.02.25.
//

import Foundation

/// A "parallel" structure for filtering PlayerEvent.
/// Each case here:
/// 1) Either ignores associated values (xxxAny)
/// 2) Or matches cases that have no associated values in PlayerEvent.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public enum PlayerEventFilter {
    /// Matches any `.seek(...)` case, regardless of Bool or currentTime
    case seekAny
    
    /// Matches `.paused` exactly (no associated values)
    case paused
    
    /// Matches `.waitingToPlayAtSpecifiedRate` (no associated values)
    case waitingToPlayAtSpecifiedRate
    
    /// Matches `.playing` (no associated values)
    case playing
    
    /// Matches any `.currentItemChanged(...)` case
    case currentItemChangedAny
    
    /// Matches `.currentItemRemoved` exactly (no associated values)
    case currentItemRemoved
    
    /// Matches any `.volumeChanged(...)` case
    case volumeChangedAny
    
    /// Matches any `.error(...)` case
    case errorAny
    
    /// Matches any `.boundsChanged(...)` case
    case boundsChangedAny
    
    /// Matches `.startedPiP` (no associated values)
    case startedPiP
    
    /// Matches `.stoppedPiP` (no associated values)
    case stoppedPiP
    
    /// Matches any `.itemStatusChanged(...)` case
    case itemStatusChangedAny
    
    /// Matches any `.duration(...)` case
    case durationAny
}

extension PlayerEventFilter {
    /// Checks whether a given `PlayerEvent` matches this filter.
    ///
    /// - Parameter event: The `PlayerEvent` to inspect.
    /// - Returns: `true` if the event belongs to this case (ignoring parameters), `false` otherwise.
    func matches(_ event: PlayerEvent) -> Bool {
        switch (self, event) {
        // Compare by case name only, ignoring associated values
        case (.seekAny, .seek):
            return true
        case (.paused, .paused):
            return true
        case (.waitingToPlayAtSpecifiedRate, .waitingToPlayAtSpecifiedRate):
            return true
        case (.playing, .playing):
            return true
        case (.currentItemChangedAny, .currentItemChanged):
            return true
        case (.currentItemRemoved, .currentItemRemoved):
            return true
        case (.volumeChangedAny, .volumeChanged):
            return true
        case (.errorAny, .error):
            return true
        case (.boundsChangedAny, .boundsChanged):
            return true
        case (.startedPiP, .startedPiP):
            return true
        case (.stoppedPiP, .stoppedPiP):
            return true
        case (.itemStatusChangedAny, .itemStatusChanged):
            return true
        case (.durationAny, .duration):
            return true

        // Default fallback: no match
        default:
            return false
        }
    }
}

extension Collection where Element == PlayerEventFilter {
    /// Checks whether any filter in this collection matches the given `PlayerEvent`.
    ///
    /// - Parameter event: The `PlayerEvent` to test.
    /// - Returns: `true` if at least one `PlayerEventFilter` in this collection matches the `event`; otherwise, `false`.
    func contains(_ event: PlayerEvent) -> Bool {
        return self.contains { filter in
            filter.matches(event)
        }
    }
}
