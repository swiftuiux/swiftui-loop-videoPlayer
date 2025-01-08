//
//  Subtitles.swift
//  swiftui-loop-videoplayer
//
//  Created by Igor Shelopaev on 07.01.25.
//

/// Represents a structure that holds the name of subtitles, conforming to `SettingsConvertible`.
///
/// Important:
/// - When using `.vtt` subtitles, a file-based container format such as MP4 or QuickTime (`.mov`)
///   generally supports embedding those subtitles as a `.text` track.
/// - Formats like HLS (`.m3u8`) typically reference `.vtt` files externally rather than merging them
///   into a single file.
/// - Attempting to merge `.vtt` subtitles into an HLS playlist via `AVMutableComposition` won't work;
///   instead, you’d attach the `.vtt` as a separate media playlist in the HLS master manifest.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct Subtitles : SettingsConvertible{
          
    /// Video file name
    let value : String
    
    // MARK: - Life circle
    
    /// Initializes a new instance with a specific video file name.
    /// - Parameter value: The string representing the video file name.
    public init(_ value: String) { self.value = value }
    
    /// Fetch settings
    @_spi(Private)
    public func asSettings() -> [Setting] {
        [.subtitles(value)]
    }
}
