//
//  SlideDialConfig.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/19/23.
//

import UIKit

public struct SlideDialConfig {
    public init() {}
    
    public var lengthRatio: CGFloat = 0.8
    public var limitation: CGFloat = Constants.rotationDegreeLimit
    
    public var scaleBarNumber = 41
    public var majorScaleBarNumber = 5
    
    public var scaleColor = UIColor.gray
    public var majorScaleColor = UIColor.white
    
    public var positiveIndicatorColor = UIColor.yellow
    public var notPositiveIndicatorColor = UIColor.white
    /// Color for negative values. Falls back to `notPositiveIndicatorColor` when nil.
    public var negativeIndicatorColor: UIColor?
    
    public var indicatorSize = CGSize(width: 40, height: 40)
    public var slideRulerHeight: CGFloat = 45
}
