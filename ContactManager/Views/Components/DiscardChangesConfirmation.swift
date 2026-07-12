//
//  DiscardChangesConfirmation.swift
//  ContactManager
//
//  Single source of truth for the "discard unsaved changes" prompt so the
//  SwiftUI "Me" screen and the UIKit-hosted Detail screen stay consistent.
//  SwiftUI screens use the `discardChangesConfirmation` modifier; UIKit-managed
//  nav bars (the pushed Detail screen) use the `makeActionSheet` factory.
//

import SwiftUI
import UIKit

enum DiscardChanges {
    static let title = "Are you sure you want to discard your changes?"
    static let discardButton = "Discard Changes"
    static let cancelButton = "Cancel"

    /// UIKit action sheet for screens whose navigation bar is managed by UIKit.
    @MainActor
    static func makeActionSheet(onDiscard: @escaping () -> Void) -> UIAlertController {
        let sheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: discardButton, style: .destructive) { _ in
            onDiscard()
        })
        sheet.addAction(UIAlertAction(title: cancelButton, style: .cancel))
        return sheet
    }
}

extension View {
    /// Attaches the discard-changes confirmation to the triggering control so
    /// the dialog anchors there (e.g. the "X" button).
    func discardChangesConfirmation(
        isPresented: Binding<Bool>,
        onDiscard: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            DiscardChanges.title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(DiscardChanges.discardButton, role: .destructive, action: onDiscard)
            Button(DiscardChanges.cancelButton, role: .cancel) {}
        }
    }
}
