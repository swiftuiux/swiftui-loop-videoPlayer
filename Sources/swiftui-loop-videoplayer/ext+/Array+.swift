//
//  Array+.swift
//  
//
//  Created by Igor Shelopaev on 09.07.2023.
//

import Foundation

extension Array where Element == Setting{
    
    /// Find first setting by case name
    /// - Parameter name: Case name
    /// - Returns: Setting
    private func first(_ name : String) -> Setting?{
        self.first(where: { $0.caseName == name })
    }
    
    /// Fetch associated value
    /// - Parameters:
    ///   - name: Case name
    ///   - defaulted: Default value
    /// - Returns: Associated value
    func fetch<T>(by name : String, defaulted : T) -> T{
        guard let value = first(name)?.associatedValue as? T else {
            return defaulted
        }
        
        return value
    }
}
