import XCTest
@testable import Mantis

final class MetalImageRendererTests: XCTestCase {
    func testBuildCITransformMapsCropRegionCornersToOutputRect() {
        let cropInfo = CropInfo(
            translation: .zero,
            rotation: 0,
            scaleX: 1,
            scaleY: 1,
            cropSize: CGSize(width: 100, height: 100),
            imageViewSize: CGSize(width: 400, height: 300),
            cropRegion: CropRegion(
                topLeft: CGPoint(x: 0.25, y: 0.2),
                topRight: CGPoint(x: 0.75, y: 0.2),
                bottomLeft: CGPoint(x: 0.25, y: 0.8),
                bottomRight: CGPoint(x: 0.75, y: 0.8)
            )
        )

        let outputSize = CGSize(width: 200, height: 180)
        let transform = MetalImageRenderer.buildCITransform(
            sourceWidth: 400,
            sourceHeight: 300,
            cropInfo: cropInfo,
            outputSize: outputSize
        )

        let sourceTopLeft = CGPoint(x: 100, y: 240)
        let sourceTopRight = CGPoint(x: 300, y: 240)
        let sourceBottomLeft = CGPoint(x: 100, y: 60)

        assertEqual(sourceTopLeft.applying(transform), CGPoint(x: 0, y: 180))
        assertEqual(sourceTopRight.applying(transform), CGPoint(x: 200, y: 180))
        assertEqual(sourceBottomLeft.applying(transform), CGPoint(x: 0, y: 0))
    }

    private func assertEqual(
        _ lhs: CGPoint,
        _ rhs: CGPoint,
        accuracy: CGFloat = 0.000001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.x, rhs.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(lhs.y, rhs.y, accuracy: accuracy, file: file, line: line)
    }
}
