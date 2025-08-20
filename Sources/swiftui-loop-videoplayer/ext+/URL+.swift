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
    /// 3) If no scheme exists -> optionally prepend https:// and parse again.
    static func validURLFromString(from raw: String, assumeHTTPSIfMissing: Bool = true) -> URL? {
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
        
        // No scheme present -> optionally add https://
        guard assumeHTTPSIfMissing else { return nil }
        guard let comps = URLComponents(string: "https://" + trimmed) else { return nil }
        guard let host = comps.host, !host.isEmpty else { return nil }
        if let port = comps.port, !(1...65535).contains(port) { return nil }
        return comps.url
    }
}
