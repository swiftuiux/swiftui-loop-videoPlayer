//
//  PlayerDelegateProtocol.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import Foundation
import AVFoundation
#if os(iOS)
import AVKit
#endif

/// Protocol to handle player-related errors.
///
/// Conforming to this protocol allows a class to respond to error events that occur within a media player context.
@available(iOS 14, macOS 11, tvOS 14, *)
@MainActor
public protocol PlayerDelegateProtocol: AnyObject{
    /// Called when an error is encountered within the media player.
    ///
    /// This method provides a way for delegate objects to respond to error conditions, allowing them to handle or
    /// display errors accordingly.
    ///
    /// - Parameter error: The specific `VPErrors` instance describing what went wrong.
    func didReceiveError(_ error: VPErrors)
    
    /// A method that handles the passage of time in the player.
    /// - Parameter seconds: The amount of time, in seconds, that has passed.
    func didPassedTime(seconds: Double)

    /// A method that handles seeking in the player.
    /// - Parameters:
    ///   - value: A Boolean indicating whether the seek was successful.
    ///   - currentTime: The current time of the player after seeking, in seconds.
    func didSeek(value: Bool, currentTime: Double)
    
    /// Called when the player has paused playback.
    ///
    /// This method is triggered when the player's `timeControlStatus` changes to `.paused`.
    func didPausePlayback()
    
    /// Called when the player is waiting to play at the specified rate.
    ///
    /// This method is triggered when the player's `timeControlStatus` changes to `.waitingToPlayAtSpecifiedRate`.
    func isWaitingToPlay()
    
    /// Called when the player starts or resumes playing.
    ///
    /// This method is triggered when the player's `timeControlStatus` changes to `.playing`.
    func didStartPlaying()
    
    /// Called when the current media item in the player changes.
    ///
    /// This method is triggered when the player's `currentItem` is updated to a new `AVPlayerItem`.
    /// - Parameter newItem: The new `AVPlayerItem` that the player has switched to, if any.
    func currentItemDidChange(to newItem: AVPlayerItem?)

    /// Called when the current media item is removed from the player.
    ///
    /// This method is triggered when the player's `currentItem` is set to `nil`, indicating that there is no longer an active media item.
    func currentItemWasRemoved()

    /// Called when the volume level of the player changes.
    ///
    /// This method is triggered when the player's `volume` property changes.
    /// - Parameter newVolume: The new volume level, expressed as a float between 0.0 (muted) and 1.0 (maximum volume).
    func volumeDidChange(to newVolume: Float)
    
    /// Notifies that the bounds have changed.
    ///
    /// - Parameter bounds: The new bounds of the main layer where we keep the video player and all vector layers. This allows a developer to recalculate and update all vector layers that lie in the CompositeLayer.

    func boundsDidChange(to bounds: CGRect)
    
    /// Called when the AVPlayerItem's status changes.
    /// - Parameter status: The new status of the AVPlayerItem.
    ///   - `.unknown`: The item is still loading or its status is not yet determined.
    ///   - `.readyToPlay`: The item is fully loaded and ready to play.
    ///   - `.failed`: The item failed to load due to an error.
    func itemStatusChanged(_ status: AVPlayerItem.Status)
    
    /// Called when the duration of the AVPlayerItem is available.
    /// - Parameter time: The total duration of the media item in `CMTime`.
    ///   - This method is only called when the item reaches `.readyToPlay`,
    ///     ensuring that the duration value is valid.
    func duration(_ time: CMTime)
    
#if os(iOS)
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController)
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController)
#endif
}
