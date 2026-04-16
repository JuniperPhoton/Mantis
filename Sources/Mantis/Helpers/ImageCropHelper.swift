//
//  ImageCropHelper.swift
//

import Foundation
import CoreGraphics
import CoreImage

/// A helper class to crop image off screen.
public class ImageCropHelper {
    public static let shared = ImageCropHelper()

    private init() {}

    public func crop(ciContext: CIContext, cgImage: CGImage, cropInfo: CropInfo) -> CGImage? {
        if let result = cropInternal(
            ciContext: ciContext,
            cgImage: cgImage,
            cropInfo: cropInfo
        ) {
            return result
        }
        return nil
    }

    func getOutputCropImageSize(size: CGSize, by cropInfo: CropInfo) -> CGSize {
        // Delegate to MetalImageRenderer so the calculation lives in one place.
        return computeOutputSize(sourceSize: size, cropInfo: cropInfo)
    }
}

/// Crops `cgImage` according to `cropInfo` on the GPU.
/// Returns `nil` on failure so callers can fall back to the CGContext path.
func cropInternal(ciContext: CIContext, cgImage: CGImage, cropInfo: CropInfo) -> CGImage? {
    let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
    let outputSize = computeOutputSize(sourceSize: sourceSize, cropInfo: cropInfo)
    guard outputSize.width > 0, outputSize.height > 0 else { return nil }

    let transform = buildCITransform(
        sourceWidth:  CGFloat(cgImage.width),
        sourceHeight: CGFloat(cgImage.height),
        cropInfo:     cropInfo,
        outputSize:   outputSize
    )

    let transformed = CIImage(cgImage: cgImage).transformed(by: transform)
    let outputRect  = CGRect(origin: .zero, size: outputSize)

    return ciContext.createCGImage(
        transformed,
        from: outputRect,
        format: .BGRA8,
        colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!
    )
}

func computeOutputSize(sourceSize: CGSize, cropInfo: CropInfo) -> CGSize {
    let zoomScaleX = abs(cropInfo.scaleX)
    let zoomScaleY = abs(cropInfo.scaleY)
    let w = round((sourceSize.width  / cropInfo.imageViewSize.width  * cropInfo.cropSize.width)  / zoomScaleX)
    let h = round((sourceSize.height / cropInfo.imageViewSize.height * cropInfo.cropSize.height) / zoomScaleY)
    return CGSize(width: w, height: h)
}

// MARK: - Transform construction

/// Builds the affine transform that maps the visible crop quadrilateral in
/// source-image CI coordinates directly onto the output image bounds.
///
/// `cropRegion` is already the most faithful description of the crop box
/// after all UIKit-space transforms have been applied, so deriving the
/// render transform from those three corners avoids accumulating small
/// coordinate-system and translation errors.
func buildCITransform(
    sourceWidth  W:  CGFloat,
    sourceHeight H:  CGFloat,
    cropInfo:        CropInfo,
    outputSize:      CGSize
) -> CGAffineTransform {
    let ow = outputSize.width
    let oh = outputSize.height
    let cropRegion = cropInfo.cropRegion

    let sourceTopLeft = CGPoint(
        x: cropRegion.topLeft.x * W,
        y: H - (cropRegion.topLeft.y * H)
    )
    let sourceTopRight = CGPoint(
        x: cropRegion.topRight.x * W,
        y: H - (cropRegion.topRight.y * H)
    )
    let sourceBottomLeft = CGPoint(
        x: cropRegion.bottomLeft.x * W,
        y: H - (cropRegion.bottomLeft.y * H)
    )

    let outputTopLeft = CGPoint(x: 0, y: oh)
    let outputTopRight = CGPoint(x: ow, y: oh)
    let outputBottomLeft = CGPoint(x: 0, y: 0)

    return affineTransform(
        mapping: (sourceTopLeft, sourceTopRight, sourceBottomLeft),
        to: (outputTopLeft, outputTopRight, outputBottomLeft)
    )
}

private func affineTransform(
    mapping source: (CGPoint, CGPoint, CGPoint),
    to destination: (CGPoint, CGPoint, CGPoint)
) -> CGAffineTransform {
    let (s0, s1, s2) = source
    let (d0, d1, d2) = destination

    let sourceBasisX = CGPoint(x: s1.x - s0.x, y: s1.y - s0.y)
    let sourceBasisY = CGPoint(x: s2.x - s0.x, y: s2.y - s0.y)
    let determinant = (sourceBasisX.x * sourceBasisY.y) - (sourceBasisY.x * sourceBasisX.y)
    guard abs(determinant) > .ulpOfOne else {
        assertionFailure("Crop region is degenerate and cannot produce an affine crop transform.")
        return .identity
    }

    let destinationBasisX = CGPoint(x: d1.x - d0.x, y: d1.y - d0.y)
    let destinationBasisY = CGPoint(x: d2.x - d0.x, y: d2.y - d0.y)

    let inverseScale = 1 / determinant
    let m00 =  sourceBasisY.y * inverseScale
    let m01 = -sourceBasisY.x * inverseScale
    let m10 = -sourceBasisX.y * inverseScale
    let m11 =  sourceBasisX.x * inverseScale

    let a = (destinationBasisX.x * m00) + (destinationBasisY.x * m10)
    let c = (destinationBasisX.x * m01) + (destinationBasisY.x * m11)
    let b = (destinationBasisX.y * m00) + (destinationBasisY.y * m10)
    let d = (destinationBasisX.y * m01) + (destinationBasisY.y * m11)

    let tx = d0.x - (a * s0.x) - (c * s0.y)
    let ty = d0.y - (b * s0.x) - (d * s0.y)

    return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
}
