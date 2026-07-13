# ContactManager

An iOS contact manager built for an iOS technical test It combines a **SwiftUI + SwiftData** app with an **Objective-C / UIKit** contacts list screen, demonstrating two-way Objective-C ↔ Swift communication.

## Requirements

- Xcode 26.x
- iOS 26.5 simulator (e.g. iPhone 17)

## Build & Run

1. Open `ContactManager.xcodeproj` in Xcode.
2. Select the `ContactManager` scheme and an iOS 26.5 simulator.
3. Press Run (Cmd+R).

From the command line:

```bash
xcodebuild -project ContactManager.xcodeproj \
  -scheme ContactManager \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## Running the Tests

Run all tests in Xcode with Cmd+U, or from the command line:

```bash
xcodebuild -project ContactManager.xcodeproj \
  -scheme ContactManager \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

- `**ContactManagerTests**` (unit): validation rules, the shared store's search-by-any-field / favorites / sort / delete-guard logic (in-memory SwiftData), and view-model image generation using a mock service.
- `**ContactManagerUITests**` (UI): creates a contact from the Objective-C list's "Nuevo" button (SwiftUI sheet) and verifies it appears in the UIKit table; plus a search flow.

## Features

- Three tabs: **Favorites**, **Contacts**, **Me**.
- Contacts/Favorites list (Objective-C/UIKit): **Edit**, **Nuevo** (+) on both list tabs, **search** (name, last name, phone, email), ascending/descending **sort**, multi-select **Favorite** / **Delete** in the top nav bar while editing, and swipe-to-delete.
- **Add Contact** (SwiftUI sheet): profile image with a **Generate** button (random image from a public API), Name / Last name / Phone / Email, favorite toggle, and validation (first name and phone required; last name and email optional but format-checked when filled). Save stays disabled until the form is valid.
- **Contact Detail** (SwiftUI hosted in UIKit): edit fields, favorite toggle, generate image; **Save** and **Cancel (X)** on the UIKit nav bar. Cancel confirms discard only when there are unsaved changes, then pops back to the list.
- **Me** (SwiftUI): the device-owner profile; read-only until **Edit** (or long-press → Edit). While editing: **X** (discard with confirmation if dirty) and **Save**; generate image.
- Local persistence via **SwiftData**; profile images stored locally.

## Architecture

MVVM (SwiftUI screens) + MVC (the UIKit list), sharing a single source of truth.

```
SwiftUI (App, MainTabView, Create/Detail/Me, @Observable view models)
        │  UIViewControllerRepresentable        ▲  UIHostingController
        ▼                                        │
Objective-C / UIKit  ── ContactsListViewController (UITableView)
        │  delegate + NotificationCenter
        ▼
ContactStore (@objc facade)  ──►  ContactDTO (@objc)     ← boundary type
        │
        ▼
SwiftData (Contact @Model, ModelContainer / ModelContext)
```

- `**ContactStore**` is an `@objc @MainActor` facade over SwiftData used by both worlds. It converts `Contact` (`@Model`, Swift-only) into `ContactDTO` (`@objc`) for the Objective-C layer.
- **Services** are protocol-based (`ImageServiceProviding`) and injected, so tests use mocks (SOLID / DI).

### Objective-C ↔ Swift interop

- **Bridging header** (`ContactManager/ContactManager-Bridging-Header.h`) exposes the Objective-C class to Swift (set via `SWIFT_OBJC_BRIDGING_HEADER`).
- **Generated header** (`ContactManager-Swift.h`) is imported inside `ContactsListViewController.m` so Objective-C can see the Swift `@objc` types (`ContactStore`, `ContactDTO`).
- **ObjC → SwiftUI**: `ContactsListViewController` sends delegate callbacks (`contactsListDidTapNew`, `contactsListDidSelectContactID:`); the Swift `Coordinator` presents the SwiftUI Create/Detail screens via `UIHostingController`.
- **SwiftUI → ObjC**: after a write, `ContactStore` posts a `NotificationCenter` notification (`ContactsDidChange`) and the Objective-C table reloads.

## Project Structure

```
ContactManager/
├── Models/Contact.swift                     SwiftData model
├── Bridge/
│   ├── ContactStore.swift                   @objc facade over SwiftData
│   ├── ContactDTO.swift                     @objc boundary type
│   └── ContactManager-Bridging-Header.h
├── ObjC/
│   ├── ContactsListViewController.h/.m       Objective-C/UIKit list
│   └── ContactsListRepresentable.swift       Representable + Coordinator
├── ViewModels/                              @Observable view models
├── Views/                                   MainTabView, Create, Detail, Me, Components
├── Services/                                ImageService, ContactValidator, ContactSeeder
└── Utilities/                               ContactFilter, ContactSortOrder

ContactManagerTests/                         Unit tests + mocks
ContactManagerUITests/                       UI tests
```

## Notes

- Images come from `https://picsum.photos/{width}/{height}` (a fresh random image per request).
- The single "Me" profile record is seeded once at launch and cannot be deleted.

