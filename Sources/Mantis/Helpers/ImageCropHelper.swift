//
//  File.swift
//
//
//  Created by Photon Juniper on 2023/12/24.
//

import Foundation
import CoreGraphics
import CoreImage

/// A helper class to crop image off screen.
public class ImageCropHelper {
    public static let shared = ImageCropHelper()
    
    private init() {
        // empty
    }
    
    public func crop(cgImage: CGImage, cropInfo: CropInfo) -> CGImage? {
        var transform = CGAffineTransform.identity
        transform.transformed(by: cropInfo)
        
        let outputSize = getOutputCropImageSize(
            size: CGSize(width: cgImage.width, height: cgImage.height),
            by: cropInfo
        )
        
        do {
            guard let transformedCGImage = try cgImage.transformedImage(
                transform,
                outputSize: outputSize,
                cropSize: cropInfo.cropSize,
                imageViewSize: cropInfo.imageViewSize
            ) else {
                return nil
            }
            
            return transformedCGImage
        } catch {
            print("*** Failed to get transfromed image ***")
            
            if let error = error as? ImageProcessError {
                print("Failed reason: \(error)")
            }
            
            return nil
        }
    }
    
    @available(*, deprecated, message: "Use crop(cgImage:cropInfo:) instead")
    public func crop(with cgImage: CGImage, cropInfo: CropInfo) -> CGImage? {
        return crop(cgImage: cgImage, cropInfo: cropInfo)
    }
    
    func getOutputCropImageSize(size: CGSize, by cropInfo: CropInfo) -> CGSize {
        let zoomScaleX = abs(cropInfo.scaleX)
        let zoomScaleY = abs(cropInfo.scaleY)
        let cropSize = cropInfo.cropSize
        let imageViewSize = cropInfo.imageViewSize
        
        let expectedWidth = round((size.width / imageViewSize.width * cropSize.width) / zoomScaleX)
        let expectedHeight = round((size.height / imageViewSize.height * cropSize.height) / zoomScaleY)
        
        return CGSize(width: expectedWidth, height: expectedHeight)
    }
}
