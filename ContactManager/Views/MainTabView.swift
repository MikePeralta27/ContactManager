//
//  MainTabView.swift
//  ContactManager
//

import SwiftUI

private enum AppTab: Hashable {
    case favorites
    case contacts
    case me
}

struct MainTabView: View {
    let store: ContactStore
    @State private var selectedTab: AppTab = .contacts   // start on Contacts

    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Favorites + Contacts both embed the same Objective-C list screen
            // (only the filter differs). The representable supplies its own
            // UINavigationController, so no SwiftUI NavigationStack is needed here.
            Tab("Favorites", systemImage: "star", value: AppTab.favorites) {
                ContactsListRepresentable(filter: .favorites, store: store)
                    .ignoresSafeArea()
            }

            Tab("Contacts", systemImage: "person.3", value: AppTab.contacts) {
                ContactsListRepresentable(filter: .all, store: store)
                    .ignoresSafeArea()
            }

            Tab("Me", systemImage: "person.crop.circle", value: AppTab.me) {
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
