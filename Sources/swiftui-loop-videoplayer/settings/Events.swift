//
//  Events.swift
//
//
//  Created by Igor Shelopaev on 14.01.25.
//

import Foundation

/// Represents a collection of event filters that can be converted into settings.
/// This struct is used to encapsulate `PlayerEventFilter` instances and provide a method
/// to transform them into an array of `Setting` objects.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct Events: SettingsConvertible {
    
    // An optional array of PlayerEventFilter objects representing event filters
    private let value: [PlayerEventFilter]?
    
    // MARK: - Life cycle
    
    /// Initializes a new instance of `Events`
    /// - Parameter value: An optional array of `PlayerEventFilter` objects, defaulting to `nil`
    public init(_ value: [PlayerEventFilter]? = nil) {
        self.value = value
    }
    
    /// Converts the event filters into an array of `Setting` objects
    /// Used for fetching settings in the application
    @_spi(Private)
    public func asSettings() -> [Setting] {
        [.events(value)]
    }
}
