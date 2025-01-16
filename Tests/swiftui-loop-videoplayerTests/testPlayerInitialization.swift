//
//  testPlaybackCommandChangesOverTime.swift
//
//
//  Created by Igor Shelopaev on 16.08.24.
//

import XCTest
import SwiftUI
@testable import swiftui_loop_videoplayer
import AVKit

final class testPlayerInitialization: XCTestCase {
    
    // Test initialization with custom parameters
    func testInitializationWithCustomParameters() {
        let playbackCommand = PlaybackCommand.pause // Example of a non-default command
        let commandBinding = Binding.constant(playbackCommand)
        let playerView = ExtVideoPlayer(
            fileName: "swipe",
            ext: "mov",
            gravity: .resizeAspectFill,
            timePublishing: CMTime(seconds: 1.5, preferredTimescale: 600),
            command: commandBinding
        )

        XCTAssertEqual(playerView.settings.name, "swipe")
        XCTAssertEqual(playerView.settings.ext, "mov")
        XCTAssertEqual(playerView.settings.gravity, .resizeAspectFill)
        XCTAssertEqual(playerView.settings.timePublishing?.seconds, 1.5)
        XCTAssertEqual(playerView.settings.timePublishing?.timescale, 600)
        XCTAssertEqual(playerView.command, playbackCommand)
    }

    // Test initialization with default parameters
    func testInitializationWithDefaultParameters() {
        let playerView = ExtVideoPlayer(fileName: "swipe")

        XCTAssertEqual(playerView.settings.name, "swipe")
        XCTAssertEqual(playerView.settings.ext, "mp4") // Default extension
        XCTAssertEqual(playerView.settings.gravity, .resizeAspect) // Default gravity
        XCTAssertNotNil(playerView.settings.timePublishing) // Default should not be nil
        XCTAssertEqual(playerView.settings.timePublishing?.seconds, 1)
        XCTAssertEqual(playerView.command, .play) // Default command
    }
    
    // Test the initializer that takes a closure returning VideoSettings
    func testExtPlayerView_InitializesWithValues() {
        let playerView = ExtVideoPlayer{
            VideoSettings{
                SourceName("swipe")
                Ext("mp8") // Set default extension here If not provided then mp4 is default
                Gravity(.resizeAspectFill)
                TimePublishing()
            }
        }
        XCTAssertEqual(playerView.settings.name, "swipe")
        XCTAssertEqual(playerView.settings.ext, "mp8")
        XCTAssertEqual(playerView.settings.gravity, .resizeAspectFill)
        XCTAssertNotEqual(playerView.settings.timePublishing, nil)
        XCTAssertEqual(playerView.command, .play)
    }
    
    // Test the initializer that takes a closure returning VideoSettings
    func testExtPlayerView_InitializesWithClosureProvidedSettings() {
        let playerView = ExtVideoPlayer {
            VideoSettings {
                SourceName("swipe")
                Ext("mp8")
                Gravity(.resizeAspectFill)
                TimePublishing(CMTime(seconds: 2, preferredTimescale: 600))
            }
        }
        XCTAssertEqual(playerView.settings.name, "swipe")
        XCTAssertEqual(playerView.settings.ext, "mp8")
        XCTAssertEqual(playerView.settings.gravity, .resizeAspectFill)
        XCTAssertEqual(playerView.settings.timePublishing?.seconds, 2)
        XCTAssertEqual(playerView.command, .play)
    }

    // Test the initializer that takes a binding to VideoSettings
    func testExtPlayerView_InitializesWithBindingProvidedSettings() {
        let initialSettings = VideoSettings {
            SourceName("swipe")
            Ext("mkv")
            Gravity(.resizeAspect)
            TimePublishing(CMTime(seconds: 1, preferredTimescale: 600))
        }
        let settings = Binding.constant(initialSettings)
        let playerView = ExtVideoPlayer(settings: settings, command: .constant(.pause))

        XCTAssertEqual(settings.wrappedValue.name, "swipe")
            XCTAssertEqual(settings.wrappedValue.ext, "mkv")
            XCTAssertEqual(settings.wrappedValue.gravity, .resizeAspect)
            XCTAssertEqual(settings.wrappedValue.timePublishing?.seconds, 1)
            XCTAssertEqual(playerView.command, .pause)
    }
    
}
