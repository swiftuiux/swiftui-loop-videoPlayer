//
//  URL+.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import Foundation


extension URL {
    
    /// Validates and returns an HTTP/HTTPS URL or nil.
    /// Strategy:
    /// 1) Parse once to detect an existing scheme (mailto, ftp, etc.).
    /// 2) If a scheme exists and it's not http/https -> reject.
    static func validURLFromString(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First parse to detect an existing scheme.
        if let pre = URLComponents(string: trimmed), let scheme = pre.scheme?.lowercased() {
            // Reject anything that is not http/https.
            guard scheme == "http" || scheme == "https" else { return nil }
            
            let comps = pre
            // Require a host
            guard let host = comps.host, !host.isEmpty else { return nil }
            // Validate port range
            if let port = comps.port, !(1...65535).contains(port) { return nil }
            return comps.url
        }
        
        return nil
    }
}
