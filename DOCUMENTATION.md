# Mantis — Image Cropping Library

Version: 2.18.0  
Platforms: iOS 17+, macOS 14+  
License: MIT

---

## What Is This?

Mantis is a Swift package that provides a full-featured, customizable image cropping UI for iOS and macOS. It works similarly to the system Photos crop editor: users can pan, pinch-to-zoom, rotate, and drag crop handles on an image, then confirm or cancel the crop.

Key capabilities:

- Multiple **crop shapes**: rectangle, square, circle, ellipse, rounded rect, diamond, heart, polygon, or an arbitrary path
- **Aspect ratio locking** with a preset list (1:1, 4:3, 16:9, etc.) and support for custom ratios
- **Rotation controls** — a circular dial or a slide ruler, both attachable to the crop view
- **Flip** horizontally and vertically
- **90-degree rotation** (clockwise / counter-clockwise)
- **Auto-adjust** — detects the horizon in the image and auto-levels it
- **Preset transformation** — restore a previous crop state programmatically
- **Sync and async** cropping modes (async is useful for large images)
- **SwiftUI support** via `UIViewControllerRepresentable`
- Fully customizable toolbar and visual appearance

---

## Architecture Overview

```
Mantis (namespace / factory functions)
│
├── CropViewController          ← the main UIViewController
│   ├── CropView                ← the interactive crop canvas (UIView)
│   │   ├── ImageContainer      ← UIImageView wrapper that holds the source image
│   │   ├── CropWorkbenchView   ← UIScrollView enabling pan & pinch-zoom
│   │   ├── CropAuxiliaryIndicatorView  ← the draggable crop-box frame + grid lines
│   │   ├── CropMaskViewManager ← the dimming/blur overlay outside the crop box
│   │   ├── CropViewModel       ← geometry & state machine for the crop box
│   │   └── RotationControlView ← RotationDial or SlideDial (optional, attached or detached)
│   └── CropToolbar             ← bottom/side toolbar with action buttons
│
└── Protocols                   ← every major component is backed by a protocol
    CropViewControllerDelegate, CropViewProtocol, CropToolbarProtocol,
    ImageContainerProtocol, CropMaskViewManagerProtocol, …
```

Every major component has a matching protocol, so each layer can be swapped with a custom implementation.

---

## How It Works

### 1. Factory → View Controller

You never instantiate `CropViewController` directly. Instead, call one of the factory functions in `Mantis.swift`:

```swift
let vc = Mantis.cropViewController(image: myImage, config: config)
vc.delegate = self
present(vc, animated: true)
```

The factory wires together all internal components:

- Creates `CropView` with the image
- Creates `ImageContainer` (the `UIImageView` inside a `UIScrollView`)
- Creates `CropAuxiliaryIndicatorView` (the draggable crop-box frame)
- Creates `CropMaskViewManager` (the dimming/blur overlay)
- Optionally attaches a `RotationDial` or `SlideDial`
- Returns a fully configured `CropViewController`

### 2. User Interaction → Crop Box Updates

`CropView` owns the interactive canvas. It is split into extension files:

| File | Responsibility |
|---|---|
| `CropView+Touches.swift` | Detects which crop-box edge/corner the user grabbed |
| `CropView+UIScrollViewDelegate.swift` | Handles pan and pinch-zoom via `UIScrollView` |
| `CropBoxFreeAspectFrameUpdater` | Updates the crop box frame when aspect ratio is free |
| `CropBoxLockedAspectFrameUpdater` | Updates the crop box frame when ratio is locked |
| `CropViewModel` | Maintains state: current crop frame, rotation angle, zoom, flip flags |

When the user drags a corner handle, `CropView` computes the new crop rect and animates it. The scroll view underneath re-centers and re-zooms the image to keep the cropped area filled.

### 3. Rotation

The rotation control view (`RotationDial` or `SlideDial`) sends angle updates back to `CropView`. `CropView` applies a `CGAffineTransform` rotation to `CropWorkbenchView` (the scroll view). The range is ±45°. For larger rotations, use the 90° rotate button.

### 4. Perspective Correction

Vertical and horizontal perspective (keystone) correction works like the Photos app and Lightroom. It is opt-in through two toolbar buttons:

```swift
config.cropToolbarConfig.toolbarButtonOptions = [.cancel, .counterclockwiseRotate,
                                                 .verticalPerspective, .horizontalPerspective,
                                                 .reset, .ratio, .done]
```

**UI.** Tapping a perspective button highlights it, and a slide ruler (−100…100) takes the place of the attached rotation control below the crop box. Tapping the highlighted button again brings the rotation control back. Tapping the value above the ruler resets that direction to 0. **Reset** clears both directions. If either button is in `toolbarButtonOptions`, `CropView` keeps room for the ruler below the crop box even when the rotation control is hidden.

Set `config.accentColor` to change the color of the active toolbar buttons and of the built-in ruler's value (yellow by default). To use your own slider, pass any `RotationControlViewProtocol` view as `perspectiveControlView` to `Mantis.cropViewController(image:config:cropToolbar:rotationControlView:perspectiveControlView:)`. `CropView` places it like an attached rotation control. It must report the value through `didUpdateRotationValue` as `Angle(degrees:)` within ±100, call `didFinishRotation` when the user lets go, and show the value it receives in `updateRotationValue(by:)` without reporting it back. `reset()` must report 0. Mantis' protocol extension defaults are internal, so an app implementing the protocol has to implement every requirement.

**Model.** `Perspective` (`Perspective.swift`) holds `horizontal` and `vertical` in −1…1, in *image space*. The image plane is tilted up to 30° in 3D, projected through a pinhole camera (focal length 1.2× the long side), and the projected quad is scaled back to fit the original image size. A positive `vertical` brings the top edge closer to the viewer, and a positive `horizontal` brings the right edge closer.

**Rendering.** The warp is the built-in `CIPerspectiveTransform` filter. Its output is composited over a clear image, so the extent stays the same as the source. Everything that depends on the image size (scroll view layout, `CropInfo`) keeps working unchanged. Areas outside the warped quad are transparent.

**Screen vs. image space.** The rulers act in *screen* space: "vertical" always means vertical on screen, even after 90° rotations or flips. `CropView` snaps the workbench transform's axes to the closest screen axes and maps between the two spaces. The stored value stays in image space.

**Keeping the crop box inside the image.** Once warped, the image is no longer a rectangle. The crop box must stay inside the warped quad, which `ImageContainer.validQuad` stores shrunk slightly so that filtered edge pixels never leak in. With the crop box fixed, every allowed image translation keeps all four crop box corners inside the quad. These limits form a convex region, which `Perspective.closestFeasiblePoint(to:)` solves directly. The existing rule that the workbench bounds stay inside the image container is added to the same set of limits.

- **Panning:** `scrollViewDidScroll` and `CropWorkbenchView.updateContentOffset()` (via `contentOffsetAdjuster`) move the image the least distance back into the allowed region. That means it slides along a slanted edge.
- **Zooming:** the minimum zoom is the smallest zoom scale at which the crop box fits *somewhere* in the quad. It is found by binary search, because zooming in shrinks the crop box in image space, so once it fits it keeps fitting. It is applied through `CropWorkbenchView.minimumZoomScaleAdjuster`, so the rotation, resize, and 90° rotation paths all respect it.
- **Crop handles:** `ImageContainer.contains(rect:fromView:tolerance:)` tests the four actual crop box corners against the quad.
- **Moving the ruler:** if the crop box no longer fits, the image zooms in around the crop box center. If the user hasn't zoomed by hand, it zooms back out as the correction is reduced.

When the perspective is zero, none of these limits apply and the old behaviour is unchanged.

**Output and persistence.** `ImageCropHelper.crop(cgImage:cropInfo:)` applies `cropInfo.perspective` to the source image before the existing crop. In-UI crops, `CropViewController.process(_:)`, and `Mantis.crop(image:by:)` all go through this single path. `Transformation.perspective` restores the correction with `presetTransformationType = .presetInfo(info:)`.

### 5. Cropping → Output Image

When the user taps **Done**:

1. `CropToolbarDelegate.didSelectCrop` is called on `CropViewController`.
2. `CropViewController.crop()` calls `cropView.crop()` (sync) or `cropView.asyncCrop(completion:)`.
3. `CropView` computes the final `CropInfo` (translation, rotation, scale, crop size, image view size, four corner coordinates, perspective).
4. `UIImage+crop(by:)` applies the perspective correction (if any) with Core Image, then applies the transform and crops the `CGImage` with `CGContext`.
5. The delegate receives `cropViewControllerDidCrop(_:cropped:transformation:cropInfo:)`.

The `Transformation` tuple lets you save and restore the exact crop state later via `config.cropViewConfig.presetTransformationType = .presetInfo(info: savedTransformation)`.

### 6. Toolbar

`CropToolbar` (or any custom `CropToolbarProtocol` implementation) renders action buttons defined by `ToolbarButtonOptions`. Each button tap calls through `CropToolbarDelegate` to `CropViewController`, which dispatches to the appropriate `CropView` method. Button visibility is controlled by an `OptionSet`:

```swift
config.cropToolbarConfig.toolbarButtonOptions = [.cancel, .done, .reset, .ratio, .counterclockwiseRotate]
```

### 7. Mask / Overlay

`CropMaskViewManager` places two views:

- **`CropDimmingView`** — a dark/light solid color overlay with a cutout shaped to the crop shape
- **`CropVisualEffectView`** — a blur layer (dark by default) over the same area

Both use a `CAShapeLayer` mask that is updated whenever the crop box changes.

---

## Public API

### Creating the crop controller

```swift
// Standard
let vc = Mantis.cropViewController(image: image, config: config)

// Generic — use your own CropViewController subclass
let vc: MyVC = Mantis.cropViewController(image: image, config: config)

// Setup an existing instance (e.g. from a Storyboard)
Mantis.setupCropViewController(existingVC, with: image, and: config)

// Crop without UI (apply a saved CropInfo)
let result = Mantis.crop(image: image, by: savedCropInfo)
```

### `Mantis.Config`

| Property | Type | Default | Purpose |
|---|---|---|---|
| `cropMode` | `CropMode` | `.sync` | Sync or async crop execution |
| `cropViewConfig` | `CropViewConfig` | default | All crop-canvas options (see below) |
| `cropToolbarConfig` | `CropToolbarConfig` | default | Toolbar appearance and button set |
| `ratioOptions` | `RatioOptions` | `.all` | Which built-in ratio presets show |
| `presetFixedRatioType` | `PresetFixedRatioType` | `.canUseMultiplePresetFixedRatio()` | Lock to one ratio or allow user selection |
| `showAttachedCropToolbar` | `Bool` | `true` | Show/hide the built-in toolbar |
| `addCustomRatio(byHorizontalWidth:andHorizontalHeight:)` | method | — | Add a custom ratio to the list |

### `CropViewConfig`

| Property | Type | Default | Purpose |
|---|---|---|---|
| `cropShapeType` | `CropShapeType` | `.rect` | Crop mask shape |
| `cropMaskVisualEffectType` | `CropMaskVisualEffectType` | `.blurDark` | Overlay style |
| `backgroundColor` | `UIColor?` | `nil` | Solid overlay color (overrides blur) |
| `minimumZoomScale` | `CGFloat` | `1` | Minimum pinch-zoom |
| `maximumZoomScale` | `CGFloat` | `15` | Maximum pinch-zoom |
| `showAttachedRotationControlView` | `Bool` | `true` | Show the rotation dial/slider |
| `builtInRotationControlViewType` | `BuiltInRotationControlViewType` | `.rotationDial()` | Dial or slide ruler |
| `presetTransformationType` | `PresetTransformationType` | `.none` | Restore a previous crop state |
| `disableCropBoxDeformation` | `Bool` | `false` | Lock crop box size (pan/zoom only) |
| `padding` | `CGFloat` | `14` | Inset between crop box and view edge |
| `rotateCropBoxFor90DegreeRotation` | `Bool` | `true` | Rotate the box when rotating 90° |

### `CropShapeType`

```swift
.rect
.square                       // always 1:1
.ellipse(maskOnly: Bool)
.circle(maskOnly: Bool)       // always 1:1
.roundedRect(radiusToShortSide: CGFloat, maskOnly: Bool)
.diamond(maskOnly: Bool)
.heart(maskOnly: Bool)
.polygon(sides: Int, offset: CGFloat, maskOnly: Bool)
.path(points: [CGPoint], maskOnly: Bool)  // normalized 0…1 coordinates
```

When `maskOnly: true`, the exported image remains rectangular; the shape is only a visual guide.

### `CropViewControllerDelegate`

```swift
// Required
func cropViewControllerDidCrop(_ vc: CropViewController,
                                cropped: UIImage,
                                transformation: Transformation,
                                cropInfo: CropInfo)

func cropViewControllerDidCancel(_ vc: CropViewController, original: UIImage)

// Optional (have default no-op implementations)
func cropViewControllerDidFailToCrop(_ vc: CropViewController, original: UIImage)
func cropViewControllerDidBeginResize(_ vc: CropViewController)
func cropViewControllerDidEndResize(_ vc: CropViewController, original: UIImage, cropInfo: CropInfo)
func cropViewControllerDidImageTransformed(_ vc: CropViewController, transformation: Transformation)
func cropViewController(_ vc: CropViewController, didBecomeResettable resettable: Bool)
```

### Key data types

```swift
// Complete description of a crop operation
typealias CropInfo = (
    translation: CGPoint,
    rotation: CGFloat,
    scaleX: CGFloat,
    scaleY: CGFloat,
    cropSize: CGSize,
    imageViewSize: CGSize,
    cropRegion: CropRegion,  // four corners of the crop rect, relative to the perspective-corrected image
    perspective: Perspective // applied to the source image before cropping
)

// Full state needed to restore a previous crop
typealias Transformation = (
    offset: CGPoint,
    rotation: CGFloat,
    scale: CGFloat,
    isManuallyZoomed: Bool,
    initialMaskFrame: CGRect,
    maskFrame: CGRect,
    cropWorkbenchViewBounds: CGRect,
    horizontallyFlipped: Bool,
    verticallyFlipped: Bool,
    perspective: Perspective
)

// Keystone correction in image space, each value in -1...1
struct Perspective {
    var horizontal: CGFloat  // > 0 brings the right edge closer to the viewer
    var vertical: CGFloat    // > 0 brings the top edge closer to the viewer
    static let zero: Perspective
}

enum PerspectiveDirection { case horizontal, vertical }
```

`CropToolbarDelegate.didSelectPerspectiveAdjustment(_:direction:)` reports which perspective ruler is active (`nil` when the rotation control is back). `CropToolbarIconProvider` can supply custom icons through `getHorizontalPerspectiveIcon()` and `getVerticalPerspectiveIcon()`.

---

## Usage Examples

### UIKit — minimal

```swift
import Mantis

class ViewController: UIViewController, CropViewControllerDelegate {

    func showCropper(image: UIImage) {
        let vc = Mantis.cropViewController(image: image)
        vc.delegate = self
        present(vc, animated: true)
    }

    func cropViewControllerDidCrop(_ vc: CropViewController,
                                   cropped: UIImage,
                                   transformation: Transformation,
                                   cropInfo: CropInfo) {
        imageView.image = cropped
        dismiss(animated: true)
    }

    func cropViewControllerDidCancel(_ vc: CropViewController, original: UIImage) {
        dismiss(animated: true)
    }
}
```

### UIKit — custom config

```swift
var config = Mantis.Config()
config.cropViewConfig.cropShapeType = .circle()
config.cropViewConfig.cropMaskVisualEffectType = .dark
config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
config.cropToolbarConfig.toolbarButtonOptions = [.cancel, .done, .reset]

let vc = Mantis.cropViewController(image: image, config: config)
vc.delegate = self
present(vc, animated: true)
```

### SwiftUI

Wrap `CropViewController` in a `UIViewControllerRepresentable`:

```swift
struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropper
        init(_ parent: ImageCropper) { self.parent = parent }

        func cropViewControllerDidCrop(_ vc: CropViewController,
                                       cropped: UIImage,
                                       transformation: Transformation,
                                       cropInfo: CropInfo) {
            parent.image = cropped
            parent.presentationMode.wrappedValue.dismiss()
        }

        func cropViewControllerDidCancel(_ vc: CropViewController, original: UIImage) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = Mantis.cropViewController(image: image!)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

### Restoring a previous crop

```swift
// Save after cropping
let savedTransformation: Transformation = transformation

// Restore later
var config = Mantis.Config()
config.cropViewConfig.presetTransformationType = .presetInfo(info: savedTransformation)
let vc = Mantis.cropViewController(image: image, config: config)
```

### Cropping without UI

```swift
// Apply a previously obtained CropInfo directly to any image
let cropped = Mantis.crop(image: originalImage, by: cropInfo)
```

---

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies** and enter the repository URL, or add to `Package.swift`:

```swift
.package(url: "https://github.com/guoyingtao/Mantis.git", from: "2.18.0")
```

### CocoaPods

```ruby
pod 'Mantis'
```

---

## Customization Points

| What | How |
|---|---|
| Replace the toolbar entirely | Implement `CropToolbarProtocol` and pass it to `Mantis.cropViewController(cropToolbar:)` |
| Replace the rotation control | Implement `RotationControlViewProtocol` and pass it to `Mantis.cropViewController(rotationControlView:)` |
| Subclass `CropViewController` | Use the generic factory overload `Mantis.cropViewController(image:) -> T` |
| Embed without a toolbar | Set `config.showAttachedCropToolbar = false` and drive crop/cancel from your own UI |
| Override language/localization | Call `Mantis.chooseLanguage(Language(code: "fr"))` or `Mantis.locateResourceBundle(by:)` |
| HDR images (iOS 18+) | Call `cropViewController.setUseHighDynamicRange(true)` after creation |
