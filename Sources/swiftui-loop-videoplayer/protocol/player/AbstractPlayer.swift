//
//  AbstractPlayer.swift
//
//
//  Created by Igor Shelopaev on 07.08.24.
//

import AVFoundation
#if canImport(CoreImage)
import CoreImage
#endif

/// Defines an abstract player protocol to be implemented by player objects, ensuring main-thread safety and compatibility with specific OS versions.
/// This protocol is designed for use with classes (reference types) only.
@available(iOS 14, macOS 11, tvOS 14, *)
@MainActor
public protocol AbstractPlayer: AnyObject {
    
    typealias ItemStatusCallback = (AVPlayerItem.Status) -> Void
    
    /// Observes the status property of the new player item.
    var itemStatusObserver: NSKeyValueObservation? { get set }
    
    /// An optional property that stores the current video settings.
    ///
    /// This property holds an instance of `VideoSettings` or nil if no settings have been configured yet.
    /// It is a computed property with both getter and setter to retrieve and update the video settings respectively.
    var currentSettings: VideoSettings? { get set }
    
    /// The delegate to be notified about errors encountered by the player.
    var delegate: PlayerDelegateProtocol? { get set }
    
    /// Retrieves the current item being played.
    var currentItem : AVPlayerItem? { get }
    
    /// The current asset being played, if available.
    var currentAsset : AVURLAsset? { get }
    
    /// Adjusts the brightness of the video. Default is 0 (no change), with positive values increasing and negative values decreasing brightness.
    var brightness: Float { get set }

    /// Controls the contrast of the video. Default is 1 (no change), with values above 1 enhancing and below 1 reducing contrast.
    var contrast: Float { get set }

    /// Holds an array of CIFilters to be applied to the video. Filters are applied in the order they are added to the array.
    var filters: [CIFilter] { get set }
    
    /// The looper responsible for continuous video playback.
    var playerLooper: AVPlayerLooper? { get set }
    
    /// The queue player that plays the video items.
    var player: AVQueuePlayer? { get set }
    
    // Playback control methods

    /// Initiates or resumes playback of the video.
    /// This method should be implemented to start playing the video from its current position.
    func play()

    /// Pauses the current video playback.
    /// This method should be implemented to pause the video, allowing it to be resumed later from the same position.
    func pause()

    /// Seeks the video to a specific time.
    /// This method moves the playback position to the specified time with precise accuracy.
    /// - Parameter time: The target time to seek to in the video timeline.
    func seek(to time: Double, play: Bool)
    
    /// Seeks to the start of the video.
    /// This method positions the playback at the beginning of the video.
    func seekToStart()
    
    /// Seeks to the end of the video.
    /// This method positions the playback at the end of the video.
    func seekToEnd()
    
    /// Mutes the video playback.
    /// This method silences the audio of the video.
    func mute()
    
    /// Unmutes the video playback.
    /// This method restores the audio of the video.
    func unmute()

    /// Adjusts the volume for the video playback.
    /// - Parameter volume: A `Float` value between 0.0 (mute) and 1.0 (full volume).
    /// If the value is out of range, it will be clamped to the nearest valid value.
    func setVolume(_ volume: Float)

    /// Adjusts the brightness of the video playback.
    /// - Parameter brightness: A `Float` value representing the brightness level. Typically ranges from -1.0 to 1.0.
    func adjustBrightness(to brightness: Float)

    /// Adjusts the contrast of the video playback.
    /// - Parameter contrast: A `Float` value representing the contrast level. Typically ranges from 0.0 to 4.0.
    func adjustContrast(to contrast: Float)

    /// Applies a Core Image filter to the video player's content.
    func applyFilter(_ value: CIFilter, _ clear : Bool)

    /// Removes all filters from the video playback.
    func removeAllFilters(apply : Bool)

    /// Selects an audio track for the video playback.
    /// - Parameter languageCode: The language code (e.g., "en" for English) of the desired audio track.
    func selectAudioTrack(languageCode: String)

    /// Sets the playback command for the video player.
    func setCommand(_ value: PlaybackCommand)
    
    /// Applies the current set of filters to the video using an AVVideoComposition.
    func applyVideoComposition()
    
    /// Updates the current playback asset, settings, and initializes playback or a specific action when the asset is ready.
    func update(settings: VideoSettings, doUpdate : Bool, callback : ((AVPlayerItem) -> Void)?)
}

extension AbstractPlayer{

    /// Retrieves the current item being played.
    ///
    /// This computed property checks if there is a current item available in the player.
    /// If available, it returns the `currentItem`; otherwise, it returns `nil`.
    var currentItem : AVPlayerItem?{
        if let currentItem = player?.currentItem {
            return currentItem
        }
        return nil
    }
    
    /// The current asset being played, if available.
    ///
    /// This computed property checks the current item of the player.
    /// If the current item exists and its asset can be cast to AVURLAsset,
    var currentAsset : AVURLAsset?{
        if let currentItem = currentItem {
            return currentItem.asset as? AVURLAsset
        }
        return nil
    }
    
    // Implementations of playback control methods

    /// Initiates playback of the video.
    /// This method starts or resumes playing the video from the current position.
    func play() {
        player?.play()
    }

    /// Pauses the video playback.
    /// This method pauses the video if it is currently playing, allowing it to be resumed later from the same position.
    func pause() {
        player?.pause()        
    }
    
    /// Clears all items from the player's queue.
    func clearPlayerQueue() {
        player?.removeAllItems()
    }
    
    /// Determines whether the media queue of the player is empty.
    func isEmptyQueue() -> Bool{
        player?.items().isEmpty ?? true
    }
    
    /// Stop and clean player
    func stop(){
        
        pause()
        
        if !isEmptyQueue() {  // Cleaning
            if isLooping(){
               unloop()
            }
            
            removeAllFilters()
            clearPlayerQueue()
        }
    }
    /// Inserts a new player item into the media queue of the player.
    /// - Parameter item: The AVPlayerItem to be inserted into the queue.
    func insert(_ item : AVPlayerItem){
        player?.insert(item, after: nil)
    }
    
    /// Creates an `AVPlayerItem` with optional subtitle merging.
    /// - Parameters:
    ///   - asset: The main video asset.
    ///   - settings: A `VideoSettings` object containing subtitle configuration.
    /// - Returns: A new `AVPlayerItem` configured with the merged or original asset.
    func createPlayerItem(with settings: VideoSettings) -> AVPlayerItem? {
        
        guard let asset = assetFor(settings) else{
            delegate?.didReceiveError(.sourceNotFound(settings.name))
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
    
    /// Clear status observer
    func clearStatusObserver(){
        guard itemStatusObserver != nil else { return }
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
    }
    
    /// Sets up an observer for the status of the provided `AVPlayerItem`.
    ///
    /// This method observes changes in the status of `newItem` and triggers the provided callback
    /// whenever the status changes to `.readyToPlay` or `.failed`. Once the callback is invoked,
    /// the observer is invalidated, ensuring that the callback is called only once.
    ///
    /// - Parameters:
    ///   - item: The `AVPlayerItem` whose status is to be observed.
    ///   - callback: A closure that is called when the item's status changes to `.readyToPlay` or `.failed`.
    func setupStateStatusObserver(for item: AVPlayerItem, callback : @escaping ItemStatusCallback) {
        
        clearStatusObserver()
        
        guard item.status == .unknown else{
            callback(item.status)
            return
        }
        
        itemStatusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] observedItem, change in
            print(observedItem.status.rawValue, "status")
            
            guard [.readyToPlay, .failed].contains(observedItem.status) else {
                return
            }
            
            callback(observedItem.status)
            
            Task { @MainActor in
                self?.clearStatusObserver()
            }
        }
    }

    /// Seeks the video to a specific time in the timeline.
    /// This method adjusts the playback position to the specified time with precise accuracy.
    /// If the target time is out of bounds (negative or beyond the duration), it will be clamped to the nearest valid time (start or end of the video).
    ///
    /// - Parameters:
    ///   - time: A `Double` value representing the target time (in seconds) to seek to in the video timeline.
    ///           If the value is less than 0, the playback position will be set to the start of the video.
    ///           If the value exceeds the video's duration, it will be set to the end.
    ///   - play: A `Bool` value indicating whether to start playback immediately after seeking.
    ///           Defaults to `false`, meaning playback will remain paused after the seek operation.
    func seek(to time: Double, play: Bool = false) {
        guard let player = player, let duration = player.currentItem?.duration else {
            onUnavailableDuration(for: time, play: play)
            return
        }
        
        guard let seekTime = getSeekTime(for: time, duration: duration) else {
            delegate?.didSeek(value: false, currentTime: time)
            return
        }
        
        player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] success in
            self?.seekCompletion(success: success, autoPlay: play)
        }
    }
    
    private func onUnavailableDuration(for time: Double, play: Bool) {
        guard let settings = currentSettings else {
            delegate?.didSeek(value: false, currentTime: time)
            return
        }
       
        let callback: ItemStatusCallback = { [weak self] status in
            if status == .readyToPlay {
                self?.seek(to: time, play: play)
            } else {
                self?.delegate?.didSeek(value: false, currentTime: time)
            }
        }
        
        update(settings: settings, doUpdate: true) { [weak self] item in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                self?.setupStateStatusObserver(for: item, callback: callback)
            }
        }
    }

    private func seekCompletion(success: Bool, autoPlay: Bool) {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        Task { @MainActor in
            delegate?.didSeek(value: success, currentTime: currentTime)
            if autoPlay {
                play()
            } else {
                pause()
            }
        }
    }
    
    /// Seeks to the start of the video.
    /// This method positions the playback at the beginning of the video.
    func seekToStart() {
        seek(to: 0)
    }
    
    /// Seeks to the end of the video.
    /// This method positions the playback at the end of the video.
    func seekToEnd() {
        if let duration = currentItem?.duration {
            let endTime = CMTimeGetSeconds(duration)
            seek(to: endTime)
        }
    }
    
    /// Mutes the video playback.
    /// This method silences the audio of the video.
    func mute() {
        player?.isMuted = true
    }
    
    /// Unmutes the video playback.
    /// This method restores the audio of the video.
    func unmute() {
        player?.isMuted = false
    }
    
    /// Sets the volume for the video playback.
    /// - Parameter volume: A `Float` value between 0.0 (mute) and 1.0 (full volume).
    /// If the value is out of range, it will be clamped to the nearest valid value.
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(volume, 1.0))  // Clamp the value between 0.0 and 1.0
        player?.volume = clampedVolume
    }
    
    /// Sets the playback speed for the video playback.
    /// - Parameter speed: A `Float` value representing the playback speed (e.g., 1.0 for normal speed, 0.5 for half speed, 2.0 for double speed).
    /// If the value is out of range (negative), it will be clamped to the nearest valid value.
    func setPlaybackSpeed(_ speed: Float) {
        let clampedSpeed = max(0.0, speed)  // Clamp to non-negative values, or adjust the upper bound as needed
        player?.rate = clampedSpeed
    }

    /// Sets the subtitles for the video playback to a specified language or turns them off.
    ///  This function is designed for use cases where the video file already contains multiple subtitle tracks (i.e., legible media tracks) embedded in its metadata. In other words, the container format (such as MP4, MOV, or QuickTime) holds one or more subtitle or closed-caption tracks that can be selected at runtime. By calling this function and providing a language code (e.g., “en”, “fr”, “de”), you instruct the AVPlayerItem to look for the corresponding subtitle track in the asset’s media selection group. If it finds a match, it will activate that subtitle track; otherwise, no subtitles will appear. Passing nil disables subtitles altogether. This approach is convenient when you want to switch between multiple embedded subtitle languages or turn them off without relying on external subtitle files (like SRT or WebVTT).
    /// - Parameters:
    ///   - language: The language code (e.g., "en" for English) for the desired subtitles.
    ///               Pass `nil` to turn off subtitles.
    func setSubtitles(to language: String?) {
        #if !os(visionOS)
        guard let currentItem = currentItem,
              let group = currentAsset?.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return
        }

        if let language = language {
            // Filter the subtitle options based on the language code
            let options = group.options.filter { option in
                guard let locale = option.locale else { return false }
                return locale.languageCode == language
            }
            // Select the first matching subtitle option
            if let option = options.first {
                currentItem.select(option, in: group)
            }
        } else {
            // Turn off subtitles by deselecting any option in the legible media selection group
            currentItem.select(nil, in: group)
        }
        #endif
    }
    
    /// Check if looping is applied
    func isLooping() -> Bool{
        playerLooper != nil
    }
    
    /// Enables looping for the current video item.
    /// This method sets up the `playerLooper` to loop the currently playing item indefinitely.
    func loop() {
        guard let player = player, let currentItem = player.currentItem else {
            return
        }

        // Check if the video is already being looped
        if isLooping() {
            return
        }

        playerLooper = AVPlayerLooper(player: player, templateItem: currentItem)
    }
    
    /// Disables looping for the current video item.
    /// This method removes the `playerLooper`, stopping the loop.
    func unloop() {
        // Check if the video is not looped (i.e., playerLooper is nil)
        guard isLooping() else {
            return // Not looped, no need to unloop
        }

        playerLooper?.disableLooping()
        playerLooper = nil
    }

    /// Adjusts the brightness of the video playback.
    /// - Parameter brightness: A `Float` value representing the brightness level. Typically ranges from -1.0 to 1.0.
    func adjustBrightness(to brightness: Float) {
        let clampedBrightness = max(-1.0, min(brightness, 1.0))  // Clamp brightness to the range [-1.0, 1.0]
        self.brightness = clampedBrightness
        applyVideoComposition()
    }

    /// Adjusts the contrast of the video playback.
    /// - Parameter contrast: A `Float` value representing the contrast level. Typically ranges from 0.0 to 4.0.
    func adjustContrast(to contrast: Float) {
        let clampedContrast = max(0.0, min(contrast, 4.0))  // Clamp contrast to the range [0.0, 4.0]
        self.contrast = clampedContrast
        applyVideoComposition()
    }

    /// Applies a Core Image filter to the video playback.
    /// This function adds the provided filter to the stack of existing filters and updates the video composition accordingly.
    /// - Parameter value: A `CIFilter` object representing the filter to be applied to the video playback.
    func applyFilter(_ value: CIFilter, _ clear : Bool) {
        if clear{
            removeAllFilters(apply: false)
        }
        appendFilter(value) // Appends the provided filter to the current stack.
        applyVideoComposition() // Updates the video composition to include the new filter.
    }
    
    /// Appends a Core Image filter to the current list of filters.
    /// - Parameters:
    ///   - value: Core Image filter to be applied.
    private func appendFilter(_ value: CIFilter) {
        filters.append(value)
    }


    /// Removes all applied CIFilters from the video playback.
    ///
    /// This function clears the array of filters and optionally re-applies the video composition
    /// to ensure the changes take effect immediately.
    ///
    /// - Parameters:
    ///   - apply: A Boolean value indicating whether to immediately apply the video composition after removing the filters.
    ///            Defaults to `true`.
    func removeAllFilters(apply : Bool = true) {
        
        guard !filters.isEmpty else { return }
        
        filters = []
        
        if apply{
            applyVideoComposition()
        }
    }
    
    /// Applies the current set of filters to the video using an AVVideoComposition.
    /// This method combines the existing filters and brightness/contrast adjustments, creates a new video composition,
    /// and assigns it to the current AVPlayerItem. The video is paused during this process to ensure smooth application.
    /// This method is not supported on Vision OS.
    func applyVideoComposition() {
        guard let player = player else { return }
        let allFilters = combineFilters(filters, brightness, contrast)
        
        #if !os(visionOS)
        // Optionally, check if the player is currently playing
        let wasPlaying = player.rate != 0
        
        // Pause the player if it was playing
        if wasPlaying {
            player.pause()
        }

        player.items().forEach{ item in
            
            let videoComposition = AVVideoComposition(asset: item.asset, applyingCIFiltersWithHandler: { request in
                handleVideoComposition(request: request, filters: allFilters)
            })

            item.videoComposition = videoComposition
        }
        
        if wasPlaying{
            player.play()
        }
        
        #endif
    }

    /// Selects an audio track for the video playback.
    /// - Parameter languageCode: The language code (e.g., "en" for English) of the desired audio track.
    func selectAudioTrack(languageCode: String) {
        guard let currentItem = currentItem else { return }
        #if !os(visionOS)
        // Retrieve the media selection group for audible tracks
        if let group = currentAsset?.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            
            // Filter options by language code using Locale
            let options = group.options.filter { option in
                return option.locale?.languageCode == languageCode
            }
            
            // Select the first matching option, if available
            if let option = options.first {
                currentItem.select(option, in: group)
            }
        }
        #endif
    }
}
