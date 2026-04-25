//
//  FakeCropMaskView.swift
//  MantisTests
//
//  Created by yingtguo on 2/5/23.
//

@testable import Mantis
import UIKit

class FakeCropMaskView: UIView, CropMaskProtocol {
    var maskLayer: CALayer?
    
    var overLayerFillColor: CGColor = UIColor.black.cgColor
    
    var cropShapeType: Mantis.CropShapeType = .rect
    
    var innerLayer: CALayer?
    
    func setMask(cropRatio: CGFloat) {
        
    }
}
