//
//  EnableVector.swift
//
//
//  Created by Igor Shelopaev on 14.01.25.
//

import Foundation

/// A structure to enable a vector layer for overlaying vector graphics.
///
/// Use this struct to activate settings that allow the addition of vector-based
/// overlays via commands, such as shapes, paths, or other scalable graphics, on top of existing content.
/// This structure is designed with optimization in mind, ensuring that extra layers
/// are not added if they are unnecessary, reducing overhead and improving performance.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct EnableVector: SettingsConvertible{
    
    // MARK: - Life circle
    
    /// Initializes a new instance
    public init() {}
    
    /// Fetch settings
    @_spi(Private)
    public func asSettings() -> [Setting] {
        [.vector]
    }
}
