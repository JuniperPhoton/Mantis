//
//  Perspective.swift
//  Mantis
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

public enum PerspectiveDirection {
    case horizontal
    case vertical
}

/// Describes a keystone (perspective) correction applied to the source image before cropping.
///
/// The image plane is tilted in 3D and projected back with a pinhole camera, which is
/// how Photos and Lightroom model their "Vertical" / "Horizontal" perspective sliders.
/// Values are in image space (before any rotation or flip), within -1...1.
public struct Perspective: Equatable {
    /// Positive values bring the right edge of the image closer to the viewer.
    public var horizontal: CGFloat
    /// Positive values bring the top edge of the image closer to the viewer.
    public var vertical: CGFloat

    public static let zero = Perspective(horizontal: 0, vertical: 0)

    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = min(1, max(-1, horizontal))
        self.vertical = min(1, max(-1, vertical))
    }

    public var isZero: Bool {
        horizontal == 0 && vertical == 0
    }

    subscript(direction: PerspectiveDirection) -> CGFloat {
        get {
            direction == .horizontal ? horizontal : vertical
        }
        set {
            switch direction {
            case .horizontal: horizontal = min(1, max(-1, newValue))
            case .vertical: vertical = min(1, max(-1, newValue))
            }
        }
    }
}

extension Perspective {
    private static let maxTiltAngle = CGFloat.pi / 6
    private static let focalLengthToLongSide: CGFloat = 1.2

    /// Keeps the crop box slightly away from the warped edges so that no transparent
    /// pixels caused by filtering get into the output.
    private static let validQuadShrinkRatio: CGFloat = 0.004
    
    static let unitQuad = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]
    
    /// The 4 corners of the warped image, normalized to the original image size.
    /// The origin is in the top left, the order is topLeft, topRight, bottomRight, bottomLeft.
    func normalizedQuad(for size: CGSize) -> [CGPoint] {
        let unitQuad = [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1)]

        guard !isZero, size.width > 0, size.height > 0 else {
            return unitQuad
        }

        let width = size.width
        let height = size.height
        let focalLength = max(width, height) * Self.focalLengthToLongSide
        let horizontalAngle = horizontal * Self.maxTiltAngle
        let verticalAngle = vertical * Self.maxTiltAngle

        // Image plane centered at the origin, y-axis up, camera looking down -z.
        let projected = Self.unitQuad.map { corner -> CGPoint in
            let x = (corner.x - 0.5) * width
            let y = (0.5 - corner.y) * height

            // Rotate around the y-axis, then around the x-axis.
            let x1 = x * cos(horizontalAngle)
            let z1 = x * sin(horizontalAngle)
            let y2 = y * cos(verticalAngle) - z1 * sin(verticalAngle)
            let z2 = y * sin(verticalAngle) + z1 * cos(verticalAngle)

            let scale = focalLength / (focalLength - z2)
            return CGPoint(x: x1 * scale, y: -y2 * scale)
        }

        // Fit the warped quad back into the original image bounds.
        let xs = projected.map { $0.x }
        let ys = projected.map { $0.y }
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let fitScale = min(width / (maxX - minX), height / (maxY - minY))
        let midX = (minX + maxX) / 2
        let midY = (minY + maxY) / 2

        return projected.map {
            CGPoint(x: ($0.x - midX) * fitScale / width + 0.5,
                    y: ($0.y - midY) * fitScale / height + 0.5)
        }
    }

    /// The area of the warped image that the crop box must stay in, so that the output never contains empty areas.
    func normalizedValidQuad(for size: CGSize) -> [CGPoint] {
        guard !isZero else {
            return Self.unitQuad
        }
        
        let quad = normalizedQuad(for: size)
        let center = CGPoint(x: quad.map { $0.x }.reduce(0, +) / 4, y: quad.map { $0.y }.reduce(0, +) / 4)
        let scale = 1 - Self.validQuadShrinkRatio
        return quad.map { CGPoint(x: center.x + ($0.x - center.x) * scale, y: center.y + ($0.y - center.y) * scale) }
    }
    
    func apply(to image: CIImage) -> CIImage {
        guard !isZero else {
            return image
        }

        let extent = image.extent
        let quad = normalizedQuad(for: extent.size)

        func toCIPoint(_ point: CGPoint) -> CGPoint {
            CGPoint(x: extent.minX + point.x * extent.width,
                    y: extent.maxY - point.y * extent.height)
        }

        let filter = CIFilter.perspectiveTransform()
        filter.inputImage = image
        filter.topLeft = toCIPoint(quad[0])
        filter.topRight = toCIPoint(quad[1])
        filter.bottomRight = toCIPoint(quad[2])
        filter.bottomLeft = toCIPoint(quad[3])

        guard let output = filter.outputImage else {
            return image
        }

        // Keep the extent identical to the source so that every crop calculation
        // based on the image size stays valid.
        return output.composited(over: CIImage(color: .clear).cropped(to: extent))
    }

    func apply(to cgImage: CGImage) -> CGImage? {
        guard !isZero else {
            return cgImage
        }

        let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let format: CIFormat = cgImage.bitsPerComponent > 8 ? .RGBAh : .RGBA8
        let warped = apply(to: CIImage(cgImage: cgImage))

        return CIContext().createCGImage(warped, from: warped.extent, format: format, colorSpace: colorSpace)
    }
}

// MARK: - Geometry
/// A linear constraint `normal · point <= limit`
struct HalfPlane {
    var normal: CGPoint
    var limit: CGFloat
    
    func contains(_ point: CGPoint, tolerance: CGFloat = 1e-6) -> Bool {
        normal.x * point.x + normal.y * point.y <= limit + tolerance
    }
}

extension Perspective {
    /// The half planes whose intersection is the convex quad.
    static func halfPlanes(ofConvexQuad quad: [CGPoint]) -> [HalfPlane] {
        let center = CGPoint(x: quad.map { $0.x }.reduce(0, +) / CGFloat(quad.count),
                             y: quad.map { $0.y }.reduce(0, +) / CGFloat(quad.count))
        
        return quad.indices.map { index in
            let p1 = quad[index]
            let p2 = quad[(index + 1) % quad.count]
            var normal = CGPoint(x: p2.y - p1.y, y: p1.x - p2.x)
            let length = hypot(normal.x, normal.y)
            if length > 0 {
                normal = CGPoint(x: normal.x / length, y: normal.y / length)
            }
            
            var limit = normal.x * p1.x + normal.y * p1.y
            if normal.x * center.x + normal.y * center.y > limit {
                normal = CGPoint(x: -normal.x, y: -normal.y)
                limit = -limit
            }
            return HalfPlane(normal: normal, limit: limit)
        }
    }
    
    static func isPoint(_ point: CGPoint, inConvexQuad quad: [CGPoint], tolerance: CGFloat) -> Bool {
        halfPlanes(ofConvexQuad: quad).allSatisfy { $0.contains(point, tolerance: tolerance) }
    }
    
    /// The constraints on a translation `t` so that every point moved by `t` stays in the convex quad.
    static func translationConstraints(keeping points: [CGPoint], inConvexQuad quad: [CGPoint]) -> [HalfPlane] {
        halfPlanes(ofConvexQuad: quad).map { plane in
            let maxProjection = points.map { plane.normal.x * $0.x + plane.normal.y * $0.y }.max() ?? 0
            return HalfPlane(normal: plane.normal, limit: plane.limit - maxProjection)
        }
    }
    
    /// The point closest to the origin which satisfies all constraints, or nil when there is none.
    /// The feasible region is a convex polygon, so the answer is either the origin, the projection
    /// of the origin onto one of the boundary lines, or a vertex where two boundary lines meet.
    static func closestFeasiblePoint(to constraints: [HalfPlane], tolerance: CGFloat = 1e-6) -> CGPoint? {
        var candidates = [CGPoint.zero]
        
        for plane in constraints {
            let lengthSquared = plane.normal.x * plane.normal.x + plane.normal.y * plane.normal.y
            guard lengthSquared > 0 else { continue }
            let ratio = plane.limit / lengthSquared
            candidates.append(CGPoint(x: plane.normal.x * ratio, y: plane.normal.y * ratio))
        }
        
        for i in constraints.indices {
            for j in constraints.indices where j > i {
                let p1 = constraints[i]
                let p2 = constraints[j]
                let determinant = p1.normal.x * p2.normal.y - p1.normal.y * p2.normal.x
                guard abs(determinant) > 1e-12 else { continue }
                candidates.append(CGPoint(x: (p1.limit * p2.normal.y - p2.limit * p1.normal.y) / determinant,
                                          y: (p1.normal.x * p2.limit - p2.normal.x * p1.limit) / determinant))
            }
        }
        
        return candidates
            .filter { candidate in constraints.allSatisfy { $0.contains(candidate, tolerance: tolerance) } }
            .min { hypot($0.x, $0.y) < hypot($1.x, $1.y) }
    }
}
