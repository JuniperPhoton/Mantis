//
//  SourceTypeSelectionView.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/20/23.
//

import SwiftUI

struct SourceTypeSelectionView: View {
    @Binding var showSourceTypeSelection: Bool
    @Binding var showCamera: Bool
    @Binding var showImagePicker: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Image Source")
                .font(.title2.bold())

            HStack(spacing: 12) {
                createSourceButton(title: "Photo Library", systemImage: "photo.on.rectangle") {
                    showImagePicker = true
                }
                createSourceButton(title: "Camera", systemImage: "camera") {
                    showCamera = true
                }
            }

            Button("Cancel", role: .cancel) {
                showSourceTypeSelection = false
            }
            .glassButtonStyle()
        }
        .padding(24)
        .presentationDetents([.height(260)])
    }

    private func createSourceButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            showSourceTypeSelection = false
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    SourceTypeSelectionView(showSourceTypeSelection: .constant(false), showCamera: .constant(false), showImagePicker: .constant(false))
}
