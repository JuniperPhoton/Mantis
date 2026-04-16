//
//  UIImageExtensions.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/30/18.
//

import UIKit

extension UIImage {
    /// Returns a CIImage with the UIImage's orientation baked into the pixel
    /// coordinate space (i.e. `extent` reflects the upright display size).
    /// This is the correct input for the Metal crop pipeline.
    func orientationCorrectedCIImage() -> CIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        return ciImage.oriented(forExifOrientation: imageOrientation.exifOrientation)
    }
}

private extension UIImage.Orientation {
    /// EXIF orientation integer expected by `CIImage.oriented(forExifOrientation:)`.
    var exifOrientation: Int32 {
        switch self {
        case .up:            return 1
        case .upMirrored:    return 2
        case .down:          return 3
        case .downMirrored:  return 4
        case .leftMirrored:  return 5
        case .right:         return 6
        case .rightMirrored: return 7
        case .left:          return 8
        @unknown default:    return 1
        }
    }
}

extension CIImage {
    func isHorizontal() -> Bool {
        let size = self.extent.size
        return size.width > size.height
    }
    
    func horizontalToVerticalRatio() -> CGFloat {
        let size = self.extent.size
        return size.width / size.height
    }
    
    func getOutputCropImageSize(by cropInfo: CropInfo) -> CGSize {
        return ImageCropHelper.shared.getOutputCropImageSize(size: extent.size, by: cropInfo)
    }
    
    func crop(ciContext: CIContext, by cropInfo: CropInfo) -> CIImage? {
        guard let fixedOrientationImage = CIContext().createCGImage(self, from: self.extent) else {
            return nil
        }
        
        guard let transformedCGImage = ImageCropHelper.shared.crop(
            ciContext: ciContext,
            cgImage: fixedOrientationImage,
            cropInfo: cropInfo
        ) else {
            return nil
        }
        
        return CIImage(cgImage: transformedCGImage)
    }
}
