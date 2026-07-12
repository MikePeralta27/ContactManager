//
//  ContactsListViewController.h
//  ContactManager
//
//  The contacts list screen, written in Objective-C / UIKit as required by the
//  technical test. It is embedded into SwiftUI via ContactsListRepresentable.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations of the Swift bridge types (defined in Swift, seen here
// via the generated ContactManager-Swift.h imported in the .m file).
@class ContactStore;

/// Events sent from the Objective-C list up to the Swift coordinator, which
/// then presents the SwiftUI screens (ObjC -> SwiftUI communication).
@protocol ContactsListViewControllerDelegate <NSObject>
- (void)contactsListDidTapNew;
- (void)contactsListDidSelectContactID:(NSString *)contactID;
@end

@interface ContactsListViewController : UITableViewController

/// Shared source of truth injected from Swift.
@property (nonatomic, strong, nullable) ContactStore *store;
/// Receives user events; the Swift coordinator conforms to it.
@property (nonatomic, weak, nullable) id<ContactsListViewControllerDelegate> delegate;
/// When YES this instance shows only favorites (the Favorites tab).
@property (nonatomic, assign) BOOL favoritesOnly;
/// When YES a "Nuevo" (+) button is shown (the Contacts tab only).
@property (nonatomic, assign) BOOL showsAddButton;

@end

NS_ASSUME_NONNULL_END
