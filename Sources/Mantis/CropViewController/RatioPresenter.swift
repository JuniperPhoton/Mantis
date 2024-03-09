//
//  RatioPresenter.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum RatioType {
    case horizontal
    case vertical
}

public protocol RatioModalPresenter {
    func present(
        items: [RatioDisplayItem],
        by viewController: UIViewController,
        in sourceView: UIView,
        didGetRatio: @escaping ((Double) -> Void)
    )
}

public class DefaultRatioModalPresenter: RatioModalPresenter {
    public func present(
        items: [RatioDisplayItem],
        by viewController: UIViewController,
        in sourceView: UIView,
        didGetRatio: @escaping ((Double) -> Void)
    ) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for ratio in items {
            let action = UIAlertAction(title: ratio.title, style: .default) { _ in
                didGetRatio(ratio.ratioValue)
            }
            actionSheet.addAction(action)
        }
        
        actionSheet.handlePopupInBigScreenIfNeeded(sourceView: sourceView)
        
        let cancelText = LocalizedHelper.getString("Mantis.Cancel", value: "Cancel")
        let cancelAction = UIAlertAction(title: cancelText, style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}

public struct RatioDisplayItem: Identifiable {
    public let isOriginal: Bool
    public let title: String
    public let ratioValue: Double
    public let id: String
    
    public init(isOriginal: Bool, title: String, ratioValue: Double, id: String) {
        self.isOriginal = isOriginal
        self.title = title
        self.ratioValue = ratioValue
        self.id = id
    }
}

final class RatioPresenter {
    var didGetRatio: ((Double) -> Void) = { _ in }
    private var type: RatioType = .vertical
    private var originalRatioH: Double
    private var ratios: [RatioItemType]
    private var fixRatiosShowType: FixedRatiosShowType = .adaptive
    private let modalPresenter: any RatioModalPresenter
    
    init(
        type: RatioType,
        originalRatioH: Double,
        ratios: [RatioItemType] = [],
        fixRatiosShowType: FixedRatiosShowType = .adaptive,
        modalPresenter: any RatioModalPresenter
    ) {
        self.type = type
        self.originalRatioH = originalRatioH
        self.ratios = ratios
        self.fixRatiosShowType = fixRatiosShowType
        self.modalPresenter = modalPresenter
    }
    
    private func getItemTitle(by ratio: RatioItemType) -> String {
        switch fixRatiosShowType {
        case .adaptive:
            return (type == .horizontal) ? ratio.nameH : ratio.nameV
        case .horizontal:
            return ratio.nameH
        case .vertical:
            return ratio.nameV
        }
    }
    
    private func getItemValue(by ratio: RatioItemType) -> Double {
        switch fixRatiosShowType {
        case .adaptive:
            return (type == .horizontal) ? ratio.ratioH : ratio.ratioV
        case .horizontal:
            return ratio.ratioH
        case .vertical:
            return ratio.ratioV
        }
    }
    
    func present(by viewController: UIViewController, in sourceView: UIView) {
        let originalText = LocalizedHelper.getString("Mantis.Original", value: "Original")
        
        let ratios = self.ratios.map { type in
            RatioDisplayItem(
                isOriginal: getItemTitle(by: type) == originalText,
                title: getItemTitle(by: type),
                ratioValue: getItemValue(by: type),
                id: UUID().uuidString
            )
        }
        modalPresenter.present(items: ratios, by: viewController, in: sourceView) { [weak self] ratio in
            self?.didGetRatio(ratio)
        }
    }
}

public extension UIAlertController {
    func handlePopupInBigScreenIfNeeded(sourceView: UIView, permittedArrowDirections: UIPopoverArrowDirection? = nil) {
        func handlePopupInBigScreen(sourceView: UIView, permittedArrowDirections: UIPopoverArrowDirection? = nil) {
            // https://stackoverflow.com/a/27823616/288724
            popoverPresentationController?.permittedArrowDirections = permittedArrowDirections ?? .any
            popoverPresentationController?.sourceView = sourceView
            popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
        if #available(macCatalyst 14.0, iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
                handlePopupInBigScreen(sourceView: sourceView, permittedArrowDirections: permittedArrowDirections)
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                handlePopupInBigScreen(sourceView: sourceView, permittedArrowDirections: permittedArrowDirections)
            }
        }
    }
}
