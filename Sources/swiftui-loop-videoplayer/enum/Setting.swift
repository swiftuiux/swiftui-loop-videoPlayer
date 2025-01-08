//
//  Setting.swift
//  
//
//  Created by Igor Shelopaev on 07.07.2023.
//

import Foundation
import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

/// Settings for loop video player
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
public enum Setting: Equatable, SettingsConvertible{
    
    /// Converts the current setting to an array containing only this setting.
    /// - Returns: An array of `Setting` containing the single instance of this setting.
    public func asSettings() -> [Setting] {
        [self]
    }
    
    /// Loop video
    case loop
    
    /// Mute video
    case mute
    
    /// Don't auto play video after initialization
    case notAutoPlay
    
    /// File name
    case name(String)

    /// File extension
    case ext(String)
    
    /// Subtitles
    case subtitles(String)
    
    /// A CMTime value representing the interval at which the player's current time should be published.
    /// If set, the player will publish periodic time updates based on this interval.
    case timePublishing(CMTime)

    /// Video gravity
    case gravity(AVLayerVideoGravity = .resizeAspect)

    /// Error text is resource is not found
    case errorText(String)

    /// Size of the error text
    case errorFontSize(CGFloat)
    
    /// Color of the error text
    case errorColor(Color)
    
    /// Do not show inner error showcase component
    case errorWidgetOff
    
    /// Case name
    var caseName: String {
        Mirror(reflecting: self).children.first?.label ?? "\(self)"
    }
    
    /// Associated value
    var associatedValue: Any? {
            
        guard let firstChild = Mirror(reflecting: self).children.first else {
            return nil
        }
        
        return firstChild.value
    }
}
