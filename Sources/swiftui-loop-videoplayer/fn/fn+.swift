//
//  fn+.swift
//
//
//  Created by Igor Shelopaev on 06.08.24.
//

import Foundation
import AVFoundation
#if canImport(CoreImage)
import CoreImage
#endif

/// Retrieves an `AVURLAsset` based on specified video settings.
/// - Parameter settings: A `VideoSettings` object containing the video name and extension.
/// - Returns: An optional `AVURLAsset`. Returns `nil` if a valid URL cannot be created or the file cannot be found in the bundle.
func assetFor(_ settings: VideoSettings) -> AVURLAsset? {
    let name = settings.name
    // If the name already includes an extension, use that; otherwise, use `settings.ext`.
    let ext = extractExtension(from: name) ?? settings.ext
    
    // Leverage the common helper to construct the `AVURLAsset`.
    return assetFrom(name: name, fileExtension: ext)
}

/// Retrieves an `AVURLAsset` for the subtitles specified in `VideoSettings`.
/// - Parameter settings: A `VideoSettings` object containing the subtitle file name.
/// - Returns: An optional `AVURLAsset` for the subtitle file, or `nil` if `subtitles` is empty or cannot be found.
func subtitlesAssetFor(_ settings: VideoSettings) -> AVURLAsset? {
    let subtitleName = settings.subtitles
    // If no subtitle name is provided, early return `nil`.
    guard !subtitleName.isEmpty else {
        return nil
    }
    
    // Use a default `.vtt` extension for subtitles.
    return assetFrom(name: subtitleName, fileExtension: "vtt")
}

/// A common helper that attempts to build an `AVURLAsset` from a given name and optional file extension.
/// - Parameters:
///   - name: The base file name or a URL string.
///   - fileExtension: An optional file extension to be appended if `name` isn't a valid URL.
/// - Returns: An optional `AVURLAsset`, or `nil` if neither a valid URL nor a local resource file is found.
fileprivate func assetFrom(name: String, fileExtension: String?) -> AVURLAsset? {
    // Attempt to create a valid URL from the provided string.
    if let url = URL.validURLFromString(name) {
        return AVURLAsset(url: url)
    }
    
    if let url = fileURL(from: name){
        return AVURLAsset(url: url)
    }
    
    // If not a valid URL, try to locate the file in the main bundle with the specified extension.
    if let fileExtension = fileExtension,
       let fileUrl = Bundle.main.url(forResource: name, withExtension: fileExtension) {
        return AVURLAsset(url: fileUrl)
    }
    
    // If all attempts fail, return `nil`.
    return nil
}


/// Attempts to create a valid `URL` from a string that starts with `"file://"`.
/// - Parameter rawString: A file URL string, e.g. `"file:///Users/igor/My Folder/File.mp4"`.
/// - Returns: A `URL` if successfully parsed; otherwise `nil`.
func fileURL(from rawString: String) -> URL? {
    guard rawString.hasPrefix("file://") else {
        // Not a file URL scheme
        return nil
    }
    // Strip off "file://"
    let pathIndex = rawString.index(rawString.startIndex, offsetBy: 7)
    let pathPortion = rawString[pathIndex...]

    guard let encodedPath = pathPortion
        .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    else { return nil }

    let finalString = "file://\(encodedPath)"
    return URL(string: finalString)
}

/// Checks whether a given filename contains an extension and returns the extension if it exists.
///
/// - Parameter name: The filename to check.
/// - Returns: An optional string containing the extension if it exists, otherwise nil.
fileprivate func extractExtension(from name: String) -> String? {
    let pattern = "^.*\\.([^\\s]+)$"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: name.utf16.count)
    
    if let match = regex?.firstMatch(in: name, options: [], range: range) {
        if let extensionRange = Range(match.range(at: 1), in: name) {
            return String(name[extensionRange])
        }
    }
    return nil
}

/// Combines an array of CIFilters with additional brightness and contrast adjustments.
///
/// This function appends brightness and contrast adjustments as CIFilters to the existing array of filters.
///
/// - Parameters:
///   - filters: An array of CIFilter objects to which the brightness and contrast filters will be added.
///   - brightness: A Float value representing the brightness adjustment to apply.
///   - contrast: A Float value representing the contrast adjustment to apply.
///
/// - Returns: An array of CIFilter objects, including the original filters and the added brightness and contrast adjustments.
internal func combineFilters(_ filters: [CIFilter],_ brightness:  Float,_ contrast: Float) -> [CIFilter] {
    var allFilters = filters
    if let filter = CIFilter(name: "CIColorControls", parameters: [kCIInputBrightnessKey: brightness]) {
        allFilters.append(filter)
    }
    if let filter = CIFilter(name: "CIColorControls", parameters: [kCIInputContrastKey: contrast]) {
        allFilters.append(filter)
    }
    return allFilters
}

/// Processes an asynchronous video composition request by applying a series of CIFilters.
/// This function ensures each frame processed conforms to specified filter effects.
///
/// - Parameters:
///   - request: An AVAsynchronousCIImageFilteringRequest object representing the current video frame to be processed.
///   - filters: An array of CIFilters to be applied sequentially to the video frame.
///
/// The function starts by clamping the source image to ensure coordinates remain within the image bounds,
/// applies each filter in the provided array, and completes by returning the modified image to the composition request.
internal func handleVideoComposition(request: AVAsynchronousCIImageFilteringRequest, filters: [CIFilter]) {
    // Start with the source image, ensuring it's clamped to avoid any coordinate issues
    var currentImage = request.sourceImage.clampedToExtent()
    
    // Apply each filter in the array to the image
    for filter in filters {
        filter.setValue(currentImage, forKey: kCIInputImageKey)
        if let outputImage = filter.outputImage {
            currentImage = outputImage.clampedToExtent()
        }
    }
    // Finish the composition request by outputting the final image
    request.finish(with: currentImage, context: nil)
}

/// Merges a video asset with an external WebVTT subtitle file into an AVMutableComposition.
/// Returns a new AVAsset that has both the video/audio and subtitle tracks.
///
/// - Note:
///   - This method supports embedding external subtitles (e.g., WebVTT) into video files
///     that can handle text tracks, such as MP4 or QuickTime (.mov).
///   - Subtitles are added as a separate track within the composition and will not be rendered
///     (burned-in) directly onto the video frames. Styling, position, and size cannot be customized.
///
/// - Parameters:
///   - videoAsset: The video asset (e.g., an MP4 file) to which the subtitles will be added.
///   - subtitleAsset: The WebVTT subtitle asset to be merged with the video.
///
/// - Returns: A new AVAsset with the video, audio, and subtitle tracks combined.
///            Returns `nil` if an error occurs during the merging process or if subtitles are unavailable.
func mergeAssetWithSubtitles(videoAsset: AVURLAsset, subtitleAsset: AVURLAsset) -> AVAsset?  {
    
    #if !os(visionOS)
    
    // 1) Find the TEXT track in the subtitle asset
    guard let textTrack = subtitleAsset.tracks(withMediaType: .text).first else {
        #if DEBUG
        print("No text track found in subtitle file.")
        #endif
        return videoAsset // Return just videoAsset if no text track
    }
    
    // Create a new composition
    let composition = AVMutableComposition()

    // 2) Copy the VIDEO track (and AUDIO track if available) from the original video
    do {
        // VIDEO
        if let videoTrack = videoAsset.tracks(withMediaType: .video).first {
            let compVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compVideoTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: videoAsset.duration),
                of: videoTrack,
                at: .zero
            )
        }
        // AUDIO (if your video has an audio track)
        if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
            let compAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compAudioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: videoAsset.duration),
                of: audioTrack,
                at: .zero
            )
        }
    } catch {
        #if DEBUG
        print("Error adding video/audio tracks: \(error)")
        #endif
        return videoAsset
    }
    
    // 3) Insert the subtitle track into the composition
    do {
        let compTextTrack = composition.addMutableTrack(
            withMediaType: .text,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        try compTextTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoAsset.duration),
            of: textTrack,
            at: .zero
        )
    } catch {
        #if DEBUG
        print("Error adding text track: \(error)")
        #endif
        return videoAsset
    }

    return composition
    
    #else
        return videoAsset
    #endif
}

/// Determines the seek time as a `CMTime` based on a specified time and the total duration of the media.
/// The function ensures that the seek time is within valid bounds (start to end of the media).
///
/// - Parameters:
///   - time: A `Double` value representing the desired time to seek to, in seconds.
///           If the value is negative, the function will seek to the start of the media.
///           If the value exceeds the total duration, the function will seek to the end.
///   - duration: A `CMTime` value representing the total duration of the media.
///               This value must be valid for the calculation to work correctly.
/// - Returns: A `CMTime` value representing the resolved seek position within the media.
func getSeekTime(for time: Double, duration : CMTime) -> CMTime?{
    
    guard duration.value != 0 else{  return nil }
    
    let endTime = CMTimeGetSeconds(duration)
    let seekTime : CMTime
    
    if time < 0 {
        // If the time is negative, seek to the start of the video
        seekTime = .zero
    } else if time >= endTime {
        // If the time exceeds the video duration, seek to the end of the video
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: duration.timescale)
        seekTime = endCMTime
    } else {
        // Otherwise, seek to the specified time
        let seekCMTime = CMTime(seconds: time, preferredTimescale: duration.timescale)
        seekTime = seekCMTime
    }
    
    return seekTime
}

/// Creates an `AVPlayerItem` with optional subtitle merging.
/// - Parameters:
///   - asset: The main video asset.
///   - settings: A `VideoSettings` object containing subtitle configuration.
/// - Returns: A new `AVPlayerItem` configured with the merged or original asset.
func createPlayerItem(with settings: VideoSettings) -> AVPlayerItem? {
    
    guard let asset = assetFor(settings) else{
        return nil
    }
    
    if let subtitleAsset = subtitlesAssetFor(settings),
       let mergedAsset = mergeAssetWithSubtitles(videoAsset: asset, subtitleAsset: subtitleAsset) {
        // Create and return a new `AVPlayerItem` using the merged asset
        return AVPlayerItem(asset: mergedAsset)
    } else {
        // Create and return a new `AVPlayerItem` using the original asset
        return AVPlayerItem(asset: asset)
    }
}
