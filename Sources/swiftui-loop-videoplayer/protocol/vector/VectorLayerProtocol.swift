//
//  VectorLayerProtocol.swift
//
//
//  Created by Igor Shelopaev on 13.08.24.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif

/// A protocol that defines methods and properties for managing vector layers within a composite layer.
///
/// This protocol is intended to be used for managing the addition and removal of vector layers,
/// which are overlaid on top of other content, such as video streams.
///
@available(iOS 14, macOS 11, tvOS 14, *)
@MainActor
public protocol LayerMakerProtocol: AnyObject {

    /// The composite layer that contains all the sublayers, including vector layers.
    ///
    /// This layer acts as a container for all vector layers added through the protocol methods.
    var compositeLayer: CALayer? { get set }

    /// The frame of the composite layer.
    ///
    /// This property defines the size and position of the composite layer within its parent view.
    var frame: CGRect { get set }

    /// The bounds of the composite layer.
    ///
    /// This property defines the drawable area of the composite layer, relative to its own coordinate system.
    var bounds: CGRect { get set }

    /// Adds a vector layer to the composite layer using a specified builder.
    ///
    /// - Parameters:
    ///   - builder: An instance conforming to `ShapeLayerBuilderProtocol` that constructs the vector layer.
    ///   - clear: A Boolean value that indicates whether to clear existing vector layers before adding the new one.
    func addVectorLayer(builder: any ShapeLayerBuilderProtocol, clear: Bool)

    /// Removes all vector layers from the composite layer.
    func removeAllVectors()
}

extension LayerMakerProtocol{
    
    /// Adds a composite layer if vector mode is enabled in the provided `VideoSettings`.
    @MainActor
    func addCompositeLayer(_ settings: VideoSettings) {
        if settings.vector {
            compositeLayer = CALayer()
        }
    }

    /// Removes the composite layer from its superlayer and sets `compositeLayer` to `nil`.
    @MainActor
    func removeCompositeLayer() {
        compositeLayer?.removeFromSuperlayer()
        compositeLayer = nil
    }
    
    /// Adds a vector layer to the composite layer using a specified builder.
    ///
    /// - Parameters:
    ///   - builder: An instance conforming to `ShapeLayerBuilderProtocol` that constructs the vector layer.
    ///   - clear: A Boolean value that indicates whether to clear existing vector layers before adding the new one.
    @MainActor 
    func addVectorLayer(builder : any ShapeLayerBuilderProtocol, clear: Bool){
        if clear{ removeAllVectors() }
        let layer = builder.build(with: (frame, bounds))
        compositeLayer?.addSublayer(layer)
    }
    
    
    /// Removes all vector layers from the composite layer.
    @MainActor 
    func removeAllVectors(){
            compositeLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
