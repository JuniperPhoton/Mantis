//
//  ImageContainer.swift
//  Mantis
//
//  Created by Echo on 10/29/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit
import PhotonMetalDisplayCore

final class ImageContainer: UIView {
    lazy private(set) var metalImageView: CustomMTKView = {
        let view = CustomMTKView(
            frame: bounds,
            device: renderer.device
        )
        view.delegate = renderer
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        
        // Allow Core Image to render to the view using the Metal compute pipeline.
        view.framebufferOnly = false
        view.delegate = renderer
        
        if let layer = view.layer as? CAMetalLayer {
            layer.isOpaque = isOpaque
        }
        
        addSubview(view)
        return view
    }()
    
    private let renderer = MetalRenderer()
    private var image: CIImage

    init(image: CIImage) {
        self.image = image
        renderer.initializeCIContext(colorSpace: nil, name: "crop")
        renderer.requestClearDestination(clearDestination: true)
        renderer.requestChanged(displayedImage: image)
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        metalImageView.frame = bounds
        renderer.requestChanged(displayedImage: image)
    }
}

extension ImageContainer: ImageContainerProtocol {
    func updateImage(_ image: CIImage) {
        self.image = image
        renderer.requestClearDestination(clearDestination: true)
        renderer.requestChanged(displayedImage: image)
        metalImageView.setNeedsDisplay()
    }
    
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat = 0.5) -> Bool {
        let newRect = view.convert(rect, to: self)

        let point1 = newRect.origin
        let point2 = CGPoint(x: newRect.maxX, y: newRect.maxY)

        let refBounds = bounds.insetBy(dx: -tolerance, dy: -tolerance)

        return refBounds.contains(point1) && refBounds.contains(point2)
    }

    func getCropRegion(withCropBoxFrame cropBoxFrame: CGRect, cropView: UIView) -> CropRegion {
        var topLeft     = cropView.convert(CGPoint(x: cropBoxFrame.minX, y: cropBoxFrame.minY), to: self)
        var topRight    = cropView.convert(CGPoint(x: cropBoxFrame.maxX, y: cropBoxFrame.minY), to: self)
        var bottomLeft  = cropView.convert(CGPoint(x: cropBoxFrame.minX, y: cropBoxFrame.maxY), to: self)
        var bottomRight = cropView.convert(CGPoint(x: cropBoxFrame.maxX, y: cropBoxFrame.maxY), to: self)

        topLeft     = CGPoint(x: topLeft.x     / bounds.width, y: topLeft.y     / bounds.height)
        topRight    = CGPoint(x: topRight.x    / bounds.width, y: topRight.y    / bounds.height)
        bottomLeft  = CGPoint(x: bottomLeft.x  / bounds.width, y: bottomLeft.y  / bounds.height)
        bottomRight = CGPoint(x: bottomRight.x / bounds.width, y: bottomRight.y / bounds.height)

        return CropRegion(topLeft: topLeft,
                          topRight: topRight,
                          bottomLeft: bottomLeft,
                          bottomRight: bottomRight)
    }
}
