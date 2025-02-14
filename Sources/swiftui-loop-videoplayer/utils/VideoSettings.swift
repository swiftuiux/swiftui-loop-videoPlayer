//
//  Settings.swift
//  
//
//  Created by Igor Shelopaev on 07.07.2023.
//

import SwiftUI
import AVKit

/// Represents a structure for video settings.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct VideoSettings: Equatable{
    
    // MARK: - Public properties
    
    /// Name of the video to play
    public let name: String
    
    /// Video extension
    public let ext: String
    
    /// Subtitles
    public let subtitles: String
    
    /// Loop video
    public let loop: Bool
    
    /// Loop video
    public let pictureInPicture: Bool
    
    /// Mute video
    public let mute: Bool
    
    /// Enable vector layer to add overlay vector graphics
    public let vector: Bool
    
    /// Disable events
    public let events: [PlayerEventFilter]?
    
    /// Don't auto play video after initialization
    public let notAutoPlay: Bool
    
    /// A CMTime value representing the interval at which the player's current time should be published.
    /// If set, the player will publish periodic time updates based on this interval.
    public let timePublishing: CMTime?
           
    /// A structure that defines how a layer displays a player’s visual content within the layer’s bounds
    public let gravity: AVLayerVideoGravity
            
    /// Are the params unique
    public var areUnique : Bool {
        unique
    }
    
    // MARK: - Private properties
    
    /// Is settings are unique
    private let unique : Bool

    // MARK: - Life circle
    
    /// Initializes a new instance of `VideoSettings` with specified values for various video properties.
    ///
    /// - Parameters:
    ///   - name: The name of the video file (excluding the extension).
    ///   - ext: The file extension of the video (e.g., `"mp4"`, `"mov"`).
    ///   - subtitles: The subtitle file name or identifier to be used for the video.
    ///   - loop: A Boolean indicating whether the video should continuously loop after playback ends.
    ///   - pictureInPicture: A Boolean indicating whether Picture-in-Picture (PiP) mode is enabled.
    ///   - mute: A Boolean indicating whether the video should start muted.
    ///   - notAutoPlay: A Boolean indicating whether the video should not start playing automatically.
    ///   - timePublishing: A `CMTime` value representing the interval for time update callbacks, or `nil` if disabled.
    ///   - gravity: The `AVLayerVideoGravity` value defining how the video should be displayed within its layer.
    ///   - enableVector: A Boolean indicating whether vector graphics rendering should be enabled for overlays.
    ///
    /// All parameters must be provided, except `timePublishing`, which can be `nil`, and `enableVector`, which defaults to `false`.
    public init(name: String, ext: String, subtitles: String, loop: Bool, pictureInPicture: Bool, mute: Bool, notAutoPlay: Bool, timePublishing: CMTime?, gravity: AVLayerVideoGravity, enableVector : Bool = false, events : [PlayerEventFilter] = []) {
        self.name = name
        self.ext = ext
        self.subtitles = subtitles
        self.loop = loop
        self.pictureInPicture = pictureInPicture
        self.mute = mute
        self.notAutoPlay = notAutoPlay
        self.timePublishing = timePublishing
        self.gravity = gravity
        self.vector = enableVector
        self.events = events
        self.unique = true
    }
        
    /// Initializes `VideoSettings` using a settings builder closure.
    /// - Parameter builder: A block builder that generates an array of settings.
    public init(@SettingsBuilder builder: () -> [Setting]){
        let settings = builder()
        
        unique = check(settings)
        
        name = settings.fetch(by : "name", defaulted: "")
        
        ext = settings.fetch(by : "ext", defaulted: "mp4")
        
        subtitles = settings.fetch(by : "subtitles", defaulted: "")
        
        gravity = settings.fetch(by : "gravity", defaulted: .resizeAspect)
                
        timePublishing = settings.fetch(by : "timePublishing", defaulted: nil)
        
        loop = settings.contains(.loop)
        
        pictureInPicture = settings.contains(.pictureInPicture)
        
        mute = settings.contains(.mute)
        
        notAutoPlay = settings.contains(.notAutoPlay)
        
        vector = settings.contains(.vector)
        
        let hasEvents = settings.contains {
            if case .events = $0 {
                return true
            }
            return false
        }
        
        if hasEvents{
            events = settings.fetch(by : "events", defaulted: []) ?? []
        }else{
            events = nil
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public extension VideoSettings {
      
    /// Checks if the asset has changed based on the provided settings and current asset.
    /// - Parameters:
    ///   - asset: The current asset being played.
    /// - Returns: A new `AVURLAsset` if the asset has changed, or `nil` if the asset remains the same.
    func isEqual(_ settings : VideoSettings?) -> Bool{
        let newAsset =  assetFor(self)
        
        guard let settings = settings else{ return false }
        
        let oldAsset = assetFor(settings)
        
        if let newUrl = newAsset?.url, let oldUrl = oldAsset?.url, newUrl != oldUrl{
            return false
        }

        return true
    }
}

/// Check if unique
/// - Parameter settings: Passed array of settings flatted by block builder
/// - Returns: True - unique False - not
fileprivate func check(_ settings : [Setting]) -> Bool{
    let cases : [String] = settings.map{ $0.caseName }
    let set = Set(cases)
    return cases.count == set.count    
}
