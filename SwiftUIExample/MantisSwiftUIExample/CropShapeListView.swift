//
//  CropShapeListView.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI

typealias CropShapeItem = (type: Mantis.CropShapeType, title: String, systemImage: String)

struct CropShapeListView: View {
    @Environment(\.dismiss) var dismiss

    let cropShapeList: [CropShapeItem] = [
        (.rect, "Rect", "rectangle"),
        (.square, "Square", "square"),
        (.ellipse(), "Ellipse", "oval"),
        (.circle(), "Circle", "circle"),
        (.polygon(sides: 5), "Pentagon", "pentagon"),
        (.polygon(sides: 6), "Hexagon", "hexagon"),
        (.roundedRect(radiusToShortSide: 0.1), "Rounded Rectangle", "app"),
        (.diamond(), "Diamond", "diamond"),
        (.heart(), "Heart", "heart"),
        (.path(points: [CGPoint(x: 0.5, y: 0),
                        CGPoint(x: 0.6, y: 0.3),
                        CGPoint(x: 1, y: 0.5),
                        CGPoint(x: 0.6, y: 0.8),
                        CGPoint(x: 0.5, y: 1),
                        CGPoint(x: 0.5, y: 0.7),
                        CGPoint(x: 0, y: 0.5)]), "Arbitrary Path", "scribble")
    ]

    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var selectedType: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                    ForEach(cropShapeList, id: \.type) { item in
                        Button {
                            cropShapeType = item.type
                            selectedType = true
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: item.systemImage)
                                    .font(.title)
                                    .foregroundStyle(.tint)
                                    .frame(height: 36)
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96)
                            .padding(8)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .glassBackground(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Crop Shape")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    CropShapeListView(cropShapeType: .constant(.rect), selectedType: .constant(false))
}
