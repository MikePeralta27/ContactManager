//
//  MeView.swift
//  ContactManager
//
//  The "Me" tab: shows the single user-profile contact. Read-only until the
//  top-left Edit button (or a long-press "Edit" context menu) enables editing.
//  While editing: X (discard, with confirmation if unsaved) on the left,
//  Save on the right.
//

import SwiftUI

struct MeView: View {
    let store: ContactStore

    @State private var viewModel = UserProfileViewModel()
    @State private var showDiscardConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProfileImageView(
                        imageData: viewModel.imageData,
                        showsGenerateButton: viewModel.isEditing,
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
                    errors: viewModel.visibleErrors,
                    requiredFields: [.firstName, .phoneNumber],
                    isEditable: viewModel.isEditing
                )
                // Long-press any field row -> "Edit" (same as the Edit button).
                .contextMenu {
                    if !viewModel.isEditing {
                        Button {
                            viewModel.isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            // Only prompt when there is something to discard;
                            // otherwise just leave edit mode.
                            if viewModel.hasUnsavedChanges {
                                showDiscardConfirmation = true
                            } else {
                                viewModel.cancelEditing(reloadFrom: store)
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .discardChangesConfirmation(
                            isPresented: $showDiscardConfirmation
                        ) {
                            viewModel.cancelEditing(reloadFrom: store)
                        }
                        .accessibilityLabel("Discard changes")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { viewModel.save(to: store) }
                            .disabled(!viewModel.isValid)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit") { viewModel.isEditing = true }
                    }
                }
            }

            .onAppear { viewModel.load(from: store) }
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
        }
    }
}

#if DEBUG
    #Preview {
        MeView(store: PreviewSupport.makeStore())
    }
#endif
