//
//  VPErrors.swift
//
//
//  Created by Igor Shelopaev on 09.07.2023.
//

import Foundation

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
/// An enumeration of possible errors that can occur in the video player.
public enum VPErrors: Error, CustomStringConvertible, Sendable {
    
    /// Error case for when there is an error with remote video playback.
    /// - Parameter error: The error that occurred during remote video playback.
    case remoteVideoError(Error?)
    
    /// Error case for when a file is not found.
    /// - Parameter name: The name of the file that was not found.
    case sourceNotFound(String)
    
    /// Error case for when settings are not unique.
    case settingsNotUnique
    
    /// Picture-in-Picture (PiP)  is not supported
    case notSupportedPiP
    
    /// Failed to load
    case failedToLoad
    
    /// A description of the error, suitable for display.
    public var description: String {
        switch self {
            case .sourceNotFound(let name):
                return "Source not found: \(name)"
            
            case .notSupportedPiP:
                return "Picture-in-Picture (PiP) is not supported on this device."
            
            case .settingsNotUnique:
                return "Settings are not unique"
            
            case .remoteVideoError(let error):
                return "Playback error: \(String(describing: error?.localizedDescription))"
            
            case .failedToLoad:
                return "Failed to load the video."
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
extension VPErrors: Equatable {
    
    /// Compares two `VPErrors` instances for equality based on specific error conditions.
    public static func ==(lhs: VPErrors, rhs: VPErrors) -> Bool {
        switch (lhs, rhs) {
        case (.remoteVideoError(let a), .remoteVideoError(let b)):
            return a?.localizedDescription == b?.localizedDescription
        case (.sourceNotFound(let a), .sourceNotFound(let b)):
            return a == b
        case (.settingsNotUnique, .settingsNotUnique):
            return true
        case (.failedToLoad, .failedToLoad):
            return true
        default:
            return false
        }
    }
}
