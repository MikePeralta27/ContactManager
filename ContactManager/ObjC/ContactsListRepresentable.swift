//
//  ContactsListRepresentable.swift
//  ContactManager
//
//  Bridges the Objective-C UIKit list into SwiftUI (UIViewControllerRepresentable),
//  and presents SwiftUI screens back from UIKit (UIHostingController).
//

import SwiftUI
import UIKit

struct ContactsListRepresentable: UIViewControllerRepresentable {
    let filter: ContactFilter
    let store: ContactStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let listVC = ContactsListViewController()
        listVC.store = store
        listVC.favoritesOnly = (filter == .favorites)
        listVC.showsAddButton = true
        listVC.delegate = context.coordinator
        listVC.title = filter.title

        let nav = UINavigationController(rootViewController: listVC)
        nav.navigationBar.prefersLargeTitles = true
        context.coordinator.navigationController = nav
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Filter/sort/search are handled inside the ObjC controller; nothing to
        // push down on SwiftUI state changes for now.
    }

    /// Translates Objective-C delegate callbacks into SwiftUI presentation.
    @MainActor
    final class Coordinator: NSObject, ContactsListViewControllerDelegate {
        let store: ContactStore
        weak var navigationController: UINavigationController?

        // Retained while a Detail screen is on-screen so the UIKit Save/Cancel/
        // Delete buttons (below) can drive the same view model the SwiftUI form
        // is bound to.
        private var detailViewModel: ContactFormViewModel?
        private var detailContactID: String?
        private weak var detailCancelButton: UIBarButtonItem?
        private weak var detailDeleteButton: UIBarButtonItem?

        init(store: ContactStore) {
            self.store = store
        }

        // ObjC -> SwiftUI: present the Create sheet.
        func contactsListDidTapNew() {
            var host: UIHostingController<AnyView>?
            let view = CreateContactSheet(store: store) { [weak self] in
                self?.navigationController?.dismiss(animated: true)
            }
            host = UIHostingController(rootView: AnyView(view))
            guard let host else { return }
            host.modalPresentationStyle = .automatic
            navigationController?.present(host, animated: true)
        }

        // ObjC -> SwiftUI: push the Detail screen for the tapped row.
        func contactsListDidSelectContactID(_ contactID: String) {
            let viewModel = ContactFormViewModel()
            if let contact = store.contact(withID: contactID) {
                viewModel.load(from: contact)
            }
            detailViewModel = viewModel
            detailContactID = contactID

            let detail = ContactDetailView(
                store: store,
                contactID: contactID,
                viewModel: viewModel
            )
            let host = UIHostingController(rootView: AnyView(detail))
            host.title = "Details"
            host.navigationItem.largeTitleDisplayMode = .never
            // Save / Delete / Cancel on the UIKit nav bar so they reliably show
            // on the pushed screen. Setting a custom left item also disables the
            // swipe-back gesture, so discarding always goes through Cancel.
            let cancelButton = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(cancelDetail)
            )
            cancelButton.accessibilityLabel = "Discard changes"
            host.navigationItem.leftBarButtonItem = cancelButton
            detailCancelButton = cancelButton

            let saveButton = UIBarButtonItem(
                title: "Save",
                style: .prominent,
                target: self,
                action: #selector(saveDetail)
            )
            let deleteButton = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(deleteDetail)
            )
            deleteButton.tintColor = .systemRed
            deleteButton.accessibilityLabel = "Delete"
            detailDeleteButton = deleteButton
            // First item is trailing-most: Save on the far right, Delete beside it.
            host.navigationItem.rightBarButtonItems = [saveButton, deleteButton]
            navigationController?.pushViewController(host, animated: true)
        }

        @objc private func saveDetail() {
            guard let detailViewModel, let detailContactID else { return }
            // Only pop back to the list if the save actually succeeded.
            if detailViewModel.saveUpdate(to: store, id: detailContactID) {
                navigationController?.popViewController(animated: true)
            }
        }

        @objc private func deleteDetail() {
            guard let detailContactID else { return }

            let alert = UIAlertController(
                title: "Are you sure you want to delete?",
                message: "This contact will be permanently deleted.",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Delete Contact", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.store.deleteContacts(ids: [detailContactID])
                self.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            // Anchor the sheet to the trash button.
            alert.popoverPresentationController?.barButtonItem = detailDeleteButton
            navigationController?.topViewController?.present(alert, animated: true)
        }

        @objc private func cancelDetail() {
            // Confirm only when there are real edits; otherwise just go back.
            guard let detailViewModel, detailViewModel.hasUnsavedChanges else {
                navigationController?.popViewController(animated: true)
                return
            }
            let sheet = DiscardChanges.makeActionSheet { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            // Anchor the popover to the Cancel button on iPad.
            sheet.popoverPresentationController?.barButtonItem = detailCancelButton
            navigationController?.topViewController?.present(sheet, animated: true)
        }
    }
}
