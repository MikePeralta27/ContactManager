//
//  ProfileImageView.swift
//  ContactManager
//

import SwiftUI

/// Circular avatar plus an optional "Generate image" button. Shows a spinner
/// and disables the button while a random image is being fetched.
struct ProfileImageView: View {
    let imageData: Data?
    var showsGenerateButton: Bool = false
    var isGenerating: Bool = false
    var onGenerate: (() -> Void)? = nil

    private let size: CGFloat = 120

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                avatar
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.quaternary, lineWidth: 1))
                    .accessibilityLabel("Profile image")

                if isGenerating {
                    Circle()
                        .fill(.black.opacity(0.35))
                        .frame(width: size, height: size)
                    ProgressView()
                        .tint(.white)
                }
            }

            if showsGenerateButton {
                Button {
                    onGenerate?()
                } label: {
                    Label("Generate", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isGenerating)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var avatar: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProfileImageView(imageData: nil, showsGenerateButton: true, isGenerating: false)
        .padding()
}
