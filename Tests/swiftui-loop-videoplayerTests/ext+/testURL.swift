//
//  testURL+.swift
//  swiftui-loop-videoplayer
//
//  Created by Igor Shelopaev on 20.08.25.
//

import XCTest
@testable import swiftui_loop_videoplayer

final class testURL: XCTestCase {

    // MARK: - Positive cases (should pass)

    func testSampleVideoURLsPass() {
        // Given: four sample URLs from the sandbox dictionary
        let urls = [
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"
        ]

        // When/Then
        for raw in urls {
            let url = URL.validURLFromString(from: raw)
            XCTAssertNotNil(url, "Expected to parse: \(raw)")
            XCTAssertEqual(url?.scheme?.lowercased(), "https")
        }
    }

    func testAddsHTTPSIfMissing() {
        // Given
        let raw = "example.com/path?x=1#y"

        // When
        let url = URL.validURLFromString(from: raw)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "example.com")
        XCTAssertEqual(url?.path, "/path")
    }

    func testTrimsWhitespace() {
        let raw = "   https://example.com/video.m3u8   "
        let url = URL.validURLFromString(from: raw)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.host, "example.com")
        XCTAssertEqual(url?.path, "/video.m3u8")
    }

    func testIPv6AndLocalHosts() {
        // IPv6 loopback
        XCTAssertNotNil(URL.validURLFromString(from: "https://[::1]"))
        // localhost
        XCTAssertNotNil(URL.validURLFromString(from: "http://localhost"))
        // IPv4 with port and query/fragment
        XCTAssertNotNil(URL.validURLFromString(from: "http://127.0.0.1:8080/path?a=1#x"))
    }

    func testIDNUnicodeHost() {
        // Unicode host (IDN). URLComponents should handle this.
        let url = URL.validURLFromString(from: "https://bücher.de")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertNotNil(url?.host)
    }

    // MARK: - Negative cases (should fail)

    func testRejectsNonHTTP() {
        XCTAssertNil(URL.validURLFromString(from: "ftp://example.com/file.mp4"))
        XCTAssertNil(URL.validURLFromString(from: "mailto:user@example.com"))
        XCTAssertNil(URL.validURLFromString(from: "file:///Users/me/movie.mp4"))
    }

    func testRejectsInvalidPort() {
        XCTAssertNil(URL.validURLFromString(from: "https://example.com:0"))
        XCTAssertNil(URL.validURLFromString(from: "https://example.com:65536"))
        XCTAssertNotNil(URL.validURLFromString(from: "https://example.com:65535"))
    }

    func testRejectsMissingHost() {
        XCTAssertNil(URL.validURLFromString(from: "https://"))
        XCTAssertNil(URL.validURLFromString(from: "https:///path-only"))
    }

    func testNoAutoSchemeOption() {
        // When auto-scheme is disabled, a bare host should fail.
        XCTAssertNil(URL.validURLFromString(from: "example.com", assumeHTTPSIfMissing: false))
    }
}
