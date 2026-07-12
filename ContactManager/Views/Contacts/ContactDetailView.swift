//
//  ContactDetailView.swift
//  ContactManager
//
//  Pushed onto the Objective-C navigation stack when a row is tapped.
//  Save and Cancel (X) live on the UIKit navigation bar (configured by the
//  Coordinator) because a SwiftUI `.toolbar` does not reliably bridge into a
//  UIKit UINavigationController when the view is hosted via UIHostingController.
//  The Coordinator owns the view model, triggers `saveUpdate` on Save, presents
//  delete confirmation from the trash button, and presents the shared discard
//  confirmation when Cancel is tapped with unsaved changes.
//

import SwiftUI

struct ContactDetailView: View {
    let store: ContactStore
    let contactID: String
    @Bindable var viewModel: ContactFormViewModel

    var body: some View {
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

#if DEBUG
#Preview {
    let store = PreviewSupport.makeStore()
    let contact = store.contacts(matchingSearch: "", favoritesOnly: false, ascending: true).first
    let viewModel = ContactFormViewModel()
    if let contact, let model = store.contact(withID: contact.id) {
        viewModel.load(from: model)
    }
    return NavigationStack {
        ContactDetailView(store: store, contactID: contact?.id ?? "", viewModel: viewModel)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {}
                }
            }
    }
}
#endif
