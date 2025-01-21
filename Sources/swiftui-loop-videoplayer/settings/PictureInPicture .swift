//
//  PictureInPicture .swift
//
//
//  Created by Igor Shelopaev on 21.01.25.
//

import Foundation


/// Represents a settings structure that enables looping functionality, conforming to `SettingsConvertible`.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public struct PictureInPicture : SettingsConvertible{
    
    // MARK: - Life circle
    
    /// Initializes a new instance
    public init() {}
    
    /// Fetch settings
    @_spi(Private)
    public func asSettings() -> [Setting] {
        [.pictureInPicture]
    }
}
