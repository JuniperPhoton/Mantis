//
//  Enum.swift
//  Mantis
//
//  Created by Echo on 07/07/22.
//  Copyright © 2022 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
    case presetNormalizedInfo(normalizedInfo: CGRect)
}

public enum PresetFixedRatioType {
    /** When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.
     */
    case alwaysUsingOnePresetFixedRatio(ratio: Double = 0)
    case canUseMultiplePresetFixedRatio(defaultRatio: Double = 0)
}

public enum CropMaskVisualEffectType {
    case blurDark
    case dark
    case light
    case custom(color: UIColor)
    case `default`
}

public enum CropShapeType: Hashable {
    case rect

    /**
      The ratio of the crop mask will always be 1:1.
     ### Notice
     It equals cropShapeType = .rect
     and presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
     */
    case square
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .rect:
            hasher.combine(0)
        case .square:
            hasher.combine(1)
        }
    }
}

public enum RatioCandidatesShowType {
    case presentRatioListFromButton
    case alwaysShowRatioList
}

public enum FixedRatiosShowType {
    case adaptive
    case horizontal
    case vertical
}

enum RotateBy90DegreeType {
    case clockwise
    case counterClockwise
    
    mutating func toggle() {
        if self == .clockwise {
            self = .counterClockwise
        } else {
            self = .clockwise
        }
    }
}

enum CropViewAuxiliaryIndicatorHandleType: Int {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

enum AutoLayoutPriorityType: Float {
    case high = 10000
    case low = 1
}

enum Constants {
    static let rotationDegreeLimit: CGFloat = 45
}
