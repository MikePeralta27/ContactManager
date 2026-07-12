//
//  MainTabView.swift
//  ContactManager
//

import SwiftUI

struct MainTabView: View {
    let store: ContactStore

    var body: some View {
        TabView {
            // Favorites + Contacts both embed the same Objective-C list screen
            // (only the filter differs). The representable supplies its own
            // UINavigationController, so no SwiftUI NavigationStack is needed here.
            Tab("Favorites", systemImage: "star") {
                ContactsListRepresentable(filter: .favorites, store: store)
                    .ignoresSafeArea()
            }

            Tab("Contacts", systemImage: "person.3") {
                ContactsListRepresentable(filter: .all, store: store)
                    .ignoresSafeArea()
            }

            Tab("Me", systemImage: "person.crop.circle") {
                MeView(store: store)
            }
        }
    }
}

#if DEBUG
#Preview {
    MainTabView(store: PreviewSupport.makeStore())
}
#endif
