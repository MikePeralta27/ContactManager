//
//  CreateContactSheet.swift
//  ContactManager
//
//  Presented from the Objective-C list's "Nuevo" button (ObjC -> SwiftUI).
//

import SwiftUI

struct CreateContactSheet: View {
    let store: ContactStore
    /// Called to dismiss the UIKit-presented hosting controller.
    let onClose: () -> Void

    @State private var viewModel = ContactFormViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProfileImageView(
                        imageData: viewModel.imageData,
                        showsGenerateButton: true,
                        isGenerating: viewModel.isGeneratingImage,
                        onGenerate: { Task { await viewModel.generateImage() } }
                    )
                }
                .listRowBackground(Color.clear)

                ContactFormFields(
                    firstName: $viewModel.firstName,
                    lastName: $viewModel.lastName,
                    phoneNumber: $viewModel.phoneNumber,
                    email: $viewModel.email,
                    isFavorite: $viewModel.isFavorite,
                    errors: viewModel.visibleErrors,
                    requiredFields: [.firstName, .phoneNumber]
                )
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { onClose() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!viewModel.isValid)
                }
            }
            .alert(
                "Image Error",
                isPresented: Binding(
                    get: { viewModel.imageErrorMessage != nil },
                    set: { if !$0 { viewModel.imageErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.imageErrorMessage ?? "")
            }
            .alert(
                "Save Error",
                isPresented: Binding(
                    get: { viewModel.saveErrorMessage != nil },
                    set: { if !$0 { viewModel.saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveErrorMessage ?? "")
            }
        }
    }

    private func save() {
        if viewModel.saveCreate(to: store) {
            onClose()
        }
    }
}

#if DEBUG
#Preview {
    CreateContactSheet(store: PreviewSupport.makeStore()) {}
}
#endif
