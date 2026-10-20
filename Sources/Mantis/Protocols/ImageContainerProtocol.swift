//
//  ImageContainerProtocol.swift
//  Mantis
//
//  Created by yingtguo on 12/15/22.
//

import CoreImage
import UIKit

protocol ImageContainerProtocol: UIView {
    /// The 4 corners of the area that has image content, normalized to bounds with the origin in the top left,
    /// in the order of topLeft, topRight, bottomRight, bottomLeft.
    /// It differs from the bounds when a perspective correction is applied.
    var validQuad: [CGPoint] { get set }
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat) -> Bool
    func getCropRegion(withCropBoxFrame cropBoxFrame: CGRect, cropView: UIView) -> CropRegion
    func updateImage(_ image: CIImage)
}
