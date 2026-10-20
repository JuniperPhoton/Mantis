//
//  FakeCropView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/2/23.
//

@testable import Mantis
import UIKit

class FakeCropView: UIView, CropViewProtocol {
    var image: CIImage = CIImage()
    
    var aspectRatioLockEnabled = false
    
    var delegate: CropViewDelegate?
    
    var perspectiveControlEnabled = false
    
    func setActivePerspectiveDirection(_ direction: PerspectiveDirection?) {
        
    }
    
    func initialSetup(delegate: CropViewDelegate, presetFixedRatioType: PresetFixedRatioType) {
    }
    
    func updateImage(_ image: CIImage) {
        
    }
    
    func getRatioType(byImageIsOriginalHorizontal isHorizontal: Bool) -> RatioType {
        .horizontal
    }
    
    func getImageHorizontalToVerticalRatio() -> Double {
        0
    }
    
    func resetComponents() {
        
    }
    
    func prepareForViewWillTransition() {
        
    }
    
    func handleViewWillTransition() {
        
    }
    
    func setFixedRatio(_ ratio: Double, zoom: Bool, presetFixedRatioType: PresetFixedRatioType) {
        
    }
    
    func rotateBy90(withRotateType rotateType: RotateBy90DegreeType, completion: @escaping () -> Void) {
        
    }
    
    func handleAlterCropper90Degree() {
        
    }
    
    func setFreeCrop() {
        
    }
    
    func handlePresetFixedRatio(_ ratio: Double, transformation: Transformation) {
        
    }
    
    func transform(byTransformInfo transformation: Transformation, isUpdateRotationControlView: Bool) {
        
    }
    
    func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false, .zero)
    }
    
    func getTransformInfo(byNormalizedInfo normalizedInfo: CGRect) -> Transformation {
        Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false, .zero)
    }
    
    func processPresetTransformation(completion: (Transformation) -> Void) {
        
    }
    
    func horizontallyFlip() {
        
    }
    
    func verticallyFlip() {
        
    }
    
    func reset() {
        
    }
    
    func makeTransformation() -> Mantis.Transformation {
        return Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false, .zero)
    }
    
    func crop() -> CropOutput {
        CropOutput(nil,
                   Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false, .zero),
                   CropInfo(.zero, .zero, .zero, .zero, .zero, .zero,
                            CropRegion(topLeft: .zero,
                                       topRight: .zero,
                                       bottomLeft: .zero,
                                       bottomRight: .zero),
                            .zero))
    }
    
    func crop(_ image: CIImage) -> CropOutput {
        CropOutput(nil,
                   Transformation(.zero, .zero, .zero, false, .zero, .zero, .zero, false, false, .zero),
                   CropInfo(.zero, .zero, .zero, .zero, .zero, .zero,
                            CropRegion(topLeft: .zero,
                                       topRight: .zero,
                                       bottomLeft: .zero,
                                       bottomRight: .zero),
                            .zero))
    }
    
    func asyncCrop(completion: @escaping (CropOutput) -> Void) {
        
    }
    
    func getCropInfo() -> CropInfo {
        CropInfo(.zero, .zero, .zero, .zero, .zero, .zero, CropRegion(topLeft: .zero, topRight: .zero, bottomLeft: .zero, bottomRight: .zero), .zero)
    }
    
    func getExpectedCropImageSize() -> CGSize {
        .zero
    }
}
