//
//  PhotonCamTests.swift
//  PhotonCamTests
//
//  Created by Photon Juniper on 2024/3/9.
//
import XCTest
@testable import MantisUtils

final class AspectRatioNumberFormatterTests: XCTestCase {
    func testFormatting() throws {
        let formatter = AspectRatioNumberFormatter()
        var output = formatter.formatNumber(0.25)
        XCTAssertEqual(output, "0.25")
        
        output = formatter.formatNumber(1.25)
        XCTAssertEqual(output, "1.25")
        
        output = formatter.formatNumber(1.25222)
        XCTAssertEqual(output, "1.25")
        
        output = formatter.formatNumber(1.00002)
        XCTAssertEqual(output, "1")
        
        output = formatter.formatNumber(1.00000)
        XCTAssertEqual(output, "1")
        
        output = formatter.formatNumber(1.10)
        XCTAssertEqual(output, "1.1")
    }
}
