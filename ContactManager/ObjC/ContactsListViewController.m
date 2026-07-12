//
//  ContactsListViewController.m
//  ContactManager
//

#import "ContactsListViewController.h"
// Generated header: lets this Objective-C file see the Swift @objc types
// (ContactStore, ContactDTO). This is the Swift -> ObjC half of the bridge.
#import "ContactManager-Swift.h"

static NSString *const kCellID = @"ContactCell";

@interface ContactsListViewController () <UISearchResultsUpdating>
@property (nonatomic, strong) NSArray<ContactDTO *> *items;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) BOOL ascending;
@property (nonatomic, copy) NSString *searchText;
@end

@implementation ContactsListViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.ascending = YES;
    self.searchText = @"";
    self.items = @[];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    [self configureNavigationBar];
    [self configureSearch];

    // Swift -> ObjC refresh: reload whenever the store changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadContacts)
                                                 name:[ContactStore contactsDidChangeNotification]
                                               object:nil];

    [self reloadContacts];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadContacts];
}

#pragma mark - Setup

- (void)configureNavigationBar {
    // Edit / Done button, top-left.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self updateRightBarButtonItems];
}

// Right-side buttons depend on editing state. We keep the multi-select
// actions (Favorite / Delete) in the top navigation bar instead of a bottom
// UIToolbar: this controller is embedded in a SwiftUI TabView, whose tab bar
// sits at the very bottom and would otherwise cover a UIKit bottom toolbar.
- (void)updateRightBarButtonItems {
    if (self.isEditing) {
        NSArray<ContactDTO *> *selected = [self selectedContacts];
        BOOL hasSelection = selected.count > 0;
        // "Selected" (filled) state only when every chosen contact is a
        // favorite; a mix of favorite/non-favorite shows the empty star.
        BOOL allFavorite = hasSelection && [self allContactsAreFavorite:selected];
        NSString *starName = allFavorite ? @"star.fill" : @"star";

        UIBarButtonItem *favorite =
            [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:starName]
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(favoriteSelected)];
        favorite.accessibilityLabel = @"Favorite";
        favorite.enabled = hasSelection;

        UIBarButtonItem *delete =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                          target:self
                                                          action:@selector(deleteSelected)];
        delete.tintColor = UIColor.systemRedColor;
        delete.accessibilityLabel = @"Delete";
        delete.enabled = hasSelection;

        // Trash appears first (trailing-most), Favorite to its left.
        self.navigationItem.rightBarButtonItems = @[delete, favorite];
        return;
    }

    UIBarButtonItem *sortItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down"]
                                          menu:[self makeSortMenu]];
    sortItem.accessibilityLabel = @"Sort";

    NSMutableArray<UIBarButtonItem *> *rightItems = [NSMutableArray array];
    if (self.showsAddButton) {
        UIBarButtonItem *addItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                          target:self
                                                          action:@selector(didTapAdd)];
        addItem.accessibilityLabel = @"Nuevo";
        [rightItems addObject:addItem];
    }
    [rightItems addObject:sortItem];
    self.navigationItem.rightBarButtonItems = rightItems;
}

- (UIMenu *)makeSortMenu {
    __weak typeof(self) weakSelf = self;
    UIAction *asc = [UIAction actionWithTitle:@"Name (A-Z)"
                                        image:[UIImage systemImageNamed:@"arrow.up"]
                                   identifier:nil
                                      handler:^(__kindof UIAction * _Nonnull action) {
        weakSelf.ascending = YES;
        [weakSelf reloadContacts];
    }];
    UIAction *desc = [UIAction actionWithTitle:@"Name (Z-A)"
                                         image:[UIImage systemImageNamed:@"arrow.down"]
                                    identifier:nil
                                       handler:^(__kindof UIAction * _Nonnull action) {
        weakSelf.ascending = NO;
        [weakSelf reloadContacts];
    }];
    asc.state = self.ascending ? UIMenuElementStateOn : UIMenuElementStateOff;
    desc.state = self.ascending ? UIMenuElementStateOff : UIMenuElementStateOn;
    return [UIMenu menuWithTitle:@"Sort" children:@[asc, desc]];
}

- (void)configureSearch {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search name or number";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

#pragma mark - Data

- (void)reloadContacts {
    if (self.store == nil) { return; }
    self.items = [self.store contactsMatchingSearch:self.searchText ?: @""
                                      favoritesOnly:self.favoritesOnly
                                          ascending:self.ascending];
    [self.tableView reloadData];
}

#pragma mark - Editing (Borrar / favorites)

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    // Swap the top-right buttons to Favorite / Delete while editing.
    [self updateRightBarButtonItems];
}

- (NSArray<ContactDTO *> *)selectedContacts {
    NSMutableArray<ContactDTO *> *selected = [NSMutableArray array];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
        [selected addObject:self.items[indexPath.row]];
    }
    return selected;
}

- (NSArray<NSString *> *)selectedContactIDs {
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (ContactDTO *contact in [self selectedContacts]) {
        [ids addObject:contact.id];
    }
    return ids;
}

- (BOOL)allContactsAreFavorite:(NSArray<ContactDTO *> *)contacts {
    for (ContactDTO *contact in contacts) {
        if (!contact.isFavorite) { return NO; }
    }
    return contacts.count > 0;
}

- (void)deleteSelected {
    NSArray<NSString *> *ids = [self selectedContactIDs];
    if (ids.count == 0) { return; }
    [self.store deleteContactsWithIDs:ids];
    [self setEditing:NO animated:YES];
}

- (void)favoriteSelected {
    NSArray<ContactDTO *> *selected = [self selectedContacts];
    if (selected.count == 0) { return; }
    // Toggle: if every selected contact is already a favorite, un-favorite
    // them all; otherwise mark the whole selection as favorite.
    BOOL newValue = ![self allContactsAreFavorite:selected];
    for (ContactDTO *contact in selected) {
        [self.store setFavorite:newValue forID:contact.id];
    }
    [self setEditing:NO animated:YES];
}

#pragma mark - Actions

- (void)didTapAdd {
    [self.delegate contactsListDidTapNew];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID
                                                           forIndexPath:indexPath];
    ContactDTO *contact = self.items[indexPath.row];

    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = contact.fullName.length > 0 ? contact.fullName : @"(No name)";
    content.secondaryText = contact.phoneNumber;
    CGFloat avatarSize = 40.0;
    content.image = [self avatarForContact:contact size:avatarSize];
    content.imageProperties.maximumSize = CGSizeMake(avatarSize, avatarSize);
    content.imageProperties.cornerRadius = avatarSize / 2.0;
    cell.contentConfiguration = content;

    // Favorite indicator on the trailing side (hidden while editing).
    if (contact.isFavorite) {
        UIImageView *star = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill"]];
        star.tintColor = UIColor.systemYellowColor;
        cell.accessoryView = star;
    } else {
        cell.accessoryView = nil;
    }
    return cell;
}

- (UIImage *)avatarForContact:(ContactDTO *)contact size:(CGFloat)size {
    if (contact.imageData != nil) {
        UIImage *image = [UIImage imageWithData:contact.imageData];
        if (image != nil) {
            // Center-crop to a square so the rounded corners render as a
            // perfect circle (picsum photos are usually non-square).
            return [self squareImage:image targetSize:size];
        }
    }
    // The SF Symbol is already circular; leave it untouched.
    return [UIImage systemImageNamed:@"person.crop.circle.fill"];
}

// Returns a square, center-cropped copy of the image scaled to size x size.
- (UIImage *)squareImage:(UIImage *)image targetSize:(CGFloat)size {
    CGFloat scale = UIScreen.mainScreen.scale;
    CGSize pixelSize = CGSizeMake(size, size);

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = scale;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:pixelSize format:format];

    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
        CGFloat side = MIN(image.size.width, image.size.height);
        CGFloat originX = (image.size.width - side) / 2.0;
        CGFloat originY = (image.size.height - side) / 2.0;

        // Scale the cropped square up to fill the target, keeping it centered.
        CGFloat drawScale = size / side;
        CGRect drawRect = CGRectMake(-originX * drawScale,
                                     -originY * drawScale,
                                     image.size.width * drawScale,
                                     image.size.height * drawScale);
        [image drawInRect:drawRect];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        // Multi-select: refresh the Favorite/Delete buttons for the new selection.
        [self updateRightBarButtonItems];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ContactDTO *contact = self.items[indexPath.row];
    [self.delegate contactsListDidSelectContactID:contact.id];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        [self updateRightBarButtonItems];
    }
}

// Swipe-to-delete in normal mode.
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactDTO *contact = self.items[indexPath.row];
    if (contact.isUserProfile) { return nil; }

    __weak typeof(self) weakSelf = self;
    UIContextualAction *delete =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"Delete"
                                              handler:^(UIContextualAction * _Nonnull action,
                                                        __kindof UIView * _Nonnull sourceView,
                                                        void (^ _Nonnull completionHandler)(BOOL)) {
        [weakSelf.store deleteContactsWithIDs:@[contact.id]];
        completionHandler(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[delete]];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchText = searchController.searchBar.text ?: @"";
    [self reloadContacts];
}

@end
