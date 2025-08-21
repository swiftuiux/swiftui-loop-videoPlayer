//
//  textArray.swift
//  swiftui-loop-videoplayer
//
//  Created by Igor  on 21.08.25.
//

import XCTest
import AVFoundation
@testable import swiftui_loop_videoplayer

final class SettingsTests: XCTestCase {

    // MARK: - events([PlayerEventFilter]?)

    func testFetch_Events_WithArray() {
        let settings: [Setting] = [.events([.playing, .paused])]
        let events: [PlayerEventFilter] = settings.fetch(by: "events", defaulted: [])
        XCTAssertEqual(events, [.playing, .paused])
    }

    func testFetch_Events_NilAssociatedValue() {
        let settings: [Setting] = [.events(nil)]
        // Optional(nil) won't cast to [PlayerEventFilter] → returns default
        let events: [PlayerEventFilter] = settings.fetch(by: "events", defaulted: [])
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - name / ext / subtitles

    func testFetch_Name_ReturnsStoredString() {
        let settings: [Setting] = [.name("teaser")]
        let value: String = settings.fetch(by: "name", defaulted: "")
        XCTAssertEqual(value, "teaser")
    }

    func testFetch_Ext_ReturnsStoredString() {
        let settings: [Setting] = [.ext("mp4")]
        let value: String = settings.fetch(by: "ext", defaulted: "mov")
        XCTAssertEqual(value, "mp4")
    }

    func testFetch_Subtitles_ReturnsStoredString() {
        let settings: [Setting] = [.subtitles("de")]
        let value: String = settings.fetch(by: "subtitles", defaulted: "en")
        XCTAssertEqual(value, "de")
    }

    // MARK: - Missing / mismatch

    func testFetch_ReturnsDefault_WhenNameMissing() {
        let settings: [Setting] = [.name("teaser")]
        let value: Int = settings.fetch(by: "fontSize", defaulted: 12)
        XCTAssertEqual(value, 12)
    }

    func testFetch_ReturnsDefault_WhenTypeMismatch() {
        let settings: [Setting] = [.name("teaser")]
        let value: Int = settings.fetch(by: "name", defaulted: 0)
        XCTAssertEqual(value, 0)
    }

    // MARK: - First match precedence

    func testFetch_PrefersFirstMatch_WhenMultipleWithSameName() {
        let settings: [Setting] = [.name("first"), .name("second")]
        let value: String = settings.fetch(by: "name", defaulted: "")
        XCTAssertEqual(value, "first")
    }

    // MARK: - Value-less cases → default

    func testFetch_Vector_ReturnsDefault() {
        let settings: [Setting] = [.vector]
        let value: Bool = settings.fetch(by: "vector", defaulted: false)
        XCTAssertFalse(value)
    }

    func testFetch_Loop_ReturnsDefault() {
        let settings: [Setting] = [.loop]
        let value: String = settings.fetch(by: "loop", defaulted: "no")
        XCTAssertEqual(value, "no")
    }

    func testFetch_PictureInPicture_ReturnsDefault() {
        let settings: [Setting] = [.pictureInPicture]
        let pip: Bool = settings.fetch(by: "pictureInPicture", defaulted: false)
        XCTAssertFalse(pip)
    }

    func testFetch_Mute_ReturnsDefault() {
        let settings: [Setting] = [.mute]
        let muted: Bool = settings.fetch(by: "mute", defaulted: false)
        XCTAssertFalse(muted)
    }

    // MARK: - timePublishing / gravity

    func testFetch_TimePublishing_CMTime() {
        let t = CMTime(seconds: 0.5, preferredTimescale: 600)
        let settings: [Setting] = [.timePublishing(t)]
        let fetched: CMTime = settings.fetch(by: "timePublishing", defaulted: .zero)
        XCTAssertEqual(CMTimeCompare(fetched, t), 0)
    }

    func testFetch_Gravity_CustomAssociatedValue() {
        let settings: [Setting] = [.gravity(.resizeAspectFill)]
        let gravity: AVLayerVideoGravity = settings.fetch(by: "gravity", defaulted: .resize)
        XCTAssertEqual(gravity, .resizeAspectFill)
    }
}
