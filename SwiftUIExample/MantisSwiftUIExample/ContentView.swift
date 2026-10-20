//
//  ContentView.swift
//  MantisSwiftUIExample
//
//  Created by Echo on 4/29/21.
//

import Mantis
import SwiftUI

struct ContentView: View {
    @State private var image: UIImage? = UIImage(named: "sunflower")!
    @State private var showingCropper = false
    @State private var showingCropShapeList = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var presetFixedRatioType: Mantis.PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    @State private var cropperType: ImageCropperType = .normal

    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showSourceTypeSelection = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        NavigationStack {
            AdaptiveStack(spacing: 24) {
                createImageHolder()
                createFeatureDemoList()
            }
            .contentMargins(20, for: .scrollContent)
            .navigationTitle("Mantis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset Image", systemImage: "arrow.counterclockwise") {
                        image = UIImage(named: "sunflower")!
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCropper, content: {
            ImageCropper(image: $image,
                         cropShapeType: $cropShapeType,
                         presetFixedRatioType: $presetFixedRatioType,
                         type: $cropperType)
            .onDisappear(perform: reset)
            .ignoresSafeArea()
        })
        .sheet(isPresented: $showingCropShapeList) {
            CropShapeListView(cropShapeType: $cropShapeType, selectedType: $showingCropper)
        }
        .sheet(isPresented: $showSourceTypeSelection) {
            SourceTypeSelectionView(showSourceTypeSelection: $showSourceTypeSelection, showCamera: $showCamera, showImagePicker: $showImagePicker)
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $image)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $image)
        }
    }

    func reset() {
        cropShapeType = .rect
        presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        cropperType = .normal
    }

    func createImageHolder() -> some View {
        Image(uiImage: image!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Button {
                    showSourceTypeSelection = true
                } label: {
                    Label("Choose Image", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .glassButtonStyle(prominent: true)
                .padding(.bottom, 16)
            }
            .padding(.vertical, 16)
    }

    func createFeatureDemoList() -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                FeatureButton(title: "Normal Crop", systemImage: "crop") {
                    showingCropper = true
                }
                FeatureButton(title: "Crop Shape", systemImage: "heart.circle") {
                    showingCropShapeList = true
                }
                FeatureButton(title: "Keep 1:1 Ratio", systemImage: "square") {
                    presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
                    showingCropper = true
                }
                FeatureButton(title: "Perspective", systemImage: "trapezoid.and.line.vertical") {
                    cropperType = .perspective
                    showingCropper = true
                }
                FeatureButton(title: "No Rotation Dial", systemImage: "dial.low") {
                    cropperType = .noRotaionDial
                    showingCropper = true
                }
                FeatureButton(title: "No Toolbar", systemImage: "menubar.rectangle") {
                    cropperType = .noAttachedToolbar
                    showingCropper = true
                }
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: horizontalSizeClass == .regular ? 360 : .infinity)
    }
}

/// A tile that opens one demo of the cropper.
struct FeatureButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(height: 28)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .padding(16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    /// Uses Liquid Glass on iOS 26 and falls back to a material background on earlier versions.
    @ViewBuilder
    func glassBackground<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// Uses the Liquid Glass button style on iOS 26 and falls back to the bordered styles on earlier versions.
    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if prominent {
                buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
            } else {
                buttonStyle(.bordered).buttonBorderShape(.capsule)
            }
        }
    }
}

#Preview {
    ContentView()
}
