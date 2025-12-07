//
//  URL+.swift
//
//
//  Created by Igor Shelopaev on 05.08.24.
//

import Foundation


public extension URL {
    
    /// Validates and returns an HTTP/HTTPS URL or nil.
    /// Strategy:
    /// 1) Parse once to detect an existing scheme (mailto, ftp, etc.).
    /// 2) If a scheme exists and it's not http/https -> reject.
    static func validURLFromString(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let pre = URLComponents(string: trimmed), let scheme = pre.scheme?.lowercased() {
            switch scheme {
            case "http", "https":
                guard let host = pre.host, !host.isEmpty else { return nil }
                if let port = pre.port, !(1...65535).contains(port) { return nil }
                return pre.url

            case "file":
                return pre.url

            default:
                return nil
            }
        }
        
        return nil
    }
}
