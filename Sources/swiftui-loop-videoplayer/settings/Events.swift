//
//  Events.swift
//
//
//  Created by Igor Shelopaev on 14.01.25.
//

import Foundation

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct Events: SettingsConvertible{
    
    /// Holds the specific AVLayerVideoGravity setting defining how video content should align within its layer.
    private let value : [PlayerEventFilter]
    
    // MARK: - Life circle
    
    /// Initializes a new instance
    public init(_ value : [PlayerEventFilter]) {
        self.value = value
    }
    
    /// Fetch settings
    @_spi(Private)
    public func asSettings() -> [Setting] {
        [.events(value)]
    }
}
