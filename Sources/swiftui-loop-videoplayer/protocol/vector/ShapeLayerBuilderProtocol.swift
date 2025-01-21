//
//  ShapeLayerProtocol.swift
//
//
//  Created by Igor Shelopaev on 13.08.24.
//

import CoreGraphics

#if canImport(QuartzCore)
import QuartzCore
#endif


/// A protocol defining a builder for creating shape layers with a unique identifier.
///
/// Conforming types will be able to construct a CAShapeLayer based on provided frame, bounds, and center.
@available(iOS 14, macOS 11, tvOS 14, *)
public protocol ShapeLayerBuilderProtocol: Identifiable {
    
    /// Unique identifier
    var id : UUID { get }
    
    /// Builds a CAShapeLayer using specified geometry.
    ///
    /// - Parameters:
    ///   - geometry: A tuple containing frame, bounds, and center as `CGRect` and `CGPoint`.
    /// - Returns: A configured `CAShapeLayer`.
    @MainActor
    func build(with geometry: (frame: CGRect, bounds: CGRect)) -> CAShapeLayer
}
