//
//  CIImageRenderer.swift
//  Mantis
//

import UIKit
import MetalKit
import CoreImage

final class CIImageRenderer: NSObject {

    let mtkView: MTKView

    var displayedCIImage: CIImage? {
        didSet { mtkView.setNeedsDisplay(mtkView.bounds) }
    }

    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    private init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.commandQueue = commandQueue
        self.ciContext = CIContext(
            mtlCommandQueue: commandQueue,
            options: [.cacheIntermediates: false]
        )
        self.mtkView = MTKView(frame: .zero, device: device)
        super.init()

        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.framebufferOnly = false
        mtkView.isOpaque = false
        mtkView.isUserInteractionEnabled = true
        mtkView.accessibilityIdentifier = "SourceImage"
        mtkView.accessibilityIgnoresInvertColors = true
        mtkView.layer.minificationFilter = .trilinear
        if let metalLayer = mtkView.layer as? CAMetalLayer {
            metalLayer.isOpaque = false
        }
        mtkView.delegate = self
    }
    
    func setUsingHighDynamicRange() {
        if let layer = mtkView.layer as? CAMetalLayer {
            // To support HDR display, setting both `wantsExtendedDynamicRangeContent` and `colorPixelFormat` is enough.
            // Internally it will check `wantsExtendedDynamicRangeContent` and `colorPixelFormat`
            // to choose a proper color space, which can be inspected later when drawing.
            layer.wantsExtendedDynamicRangeContent = true
            mtkView.colorPixelFormat = MTLPixelFormat.rgba16Float
        }
    }

    static func create() -> CIImageRenderer? {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else { return nil }
        return CIImageRenderer(device: device, commandQueue: queue)
    }

    deinit {
        mtkView.delegate = nil
    }
}

extension CIImageRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let image = displayedCIImage,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let drawableSize = view.drawableSize

        // Scale to fill the entire drawable independently on each axis.
        // ImageContainer is already sized to match the image's aspect ratio by the
        // scroll view, so no letterboxing is needed. Using min(scaleX, scaleY) here
        // would introduce transparent borders whose (0,0,0,0) pixels create a dark
        // gradient at the image edge when UIKit bilinearly filters the rotated layer.
        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let destination = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: view.colorPixelFormat,
            commandBuffer: commandBuffer
        ) { drawable.texture }

        _ = try? ciContext.startTask(toRender: scaled, to: destination)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
