//
//  File.swift
//  
//
//  Created by Photon Juniper on 2024/3/9.
//

import Foundation

public class AspectRatioNumberFormatter {
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    public init() {
        // empty
    }
    
    /// Format the number to a string, which:
    /// - Keep up to 2 fraction digits
    public func formatNumber(_ number: Double) -> String {
        guard let formattedNumber = formatter.string(from: NSNumber(value: number)) else {
            return ""
        }
        return formattedNumber
    }
}
