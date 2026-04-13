//
//  ImageCropper.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI
import CoreImage

enum ImageCropperType {
    case normal
    case noRotaionDial
    case noAttachedToolbar
}

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var presetFixedRatioType: Mantis.PresetFixedRatioType
    @Binding var type: ImageCropperType

    @Environment(\.dismiss) var dismiss

    class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropper

        init(_ parent: ImageCropper) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(
            _ cropViewController: Mantis.CropViewController,
            cropped: CIImage,
            transformation: Transformation,
            cropInfo: CropInfo
        ) {
            // Render CIImage to UIImage for display/storage
            if let cgImage = CIContext().createCGImage(cropped, from: cropped.extent) {
                parent.image = UIImage(cgImage: cgImage)
            }
            print("transformation is \(transformation)")
            parent.dismiss()
        }

        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: CIImage) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch type {
        case .normal:
            return makeNormalImageCropper(context: context)
        case .noRotaionDial:
            return makeImageCropperHiddingRotationDial(context: context)
        case .noAttachedToolbar:
            return makeImageCropperWithoutAttachedToolbar(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension ImageCropper {
    private func ciImage(from uiImage: UIImage?) -> CIImage {
        guard let uiImage else { return CIImage.empty() }
        let raw = CIImage(image: uiImage) ?? CIImage.empty()
        return raw.oriented(CGImagePropertyOrientation(uiImage.imageOrientation))
    }

    func makeNormalImageCropper(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        let cropViewController = Mantis.cropViewController(image: ciImage(from: image),
                                                           config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func makeImageCropperHiddingRotationDial(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false
        let cropViewController = Mantis.cropViewController(image: ciImage(from: image), config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    func makeImageCropperWithoutAttachedToolbar(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        let cropViewController: CustomViewController = Mantis.cropViewController(image: ciImage(from: image), config: config)
        cropViewController.delegate = context.coordinator
        return UINavigationController(rootViewController: cropViewController)
    }
}
