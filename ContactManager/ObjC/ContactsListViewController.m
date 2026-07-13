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
/// Kept while editing so the delete confirmation can anchor to the trash button.
@property (nonatomic, weak) UIBarButtonItem *deleteBarButtonItem;
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

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kCellID];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    [self configureNavigationBar];
    [self configureSearch];

    // Swift -> ObjC refresh: reload whenever the store changes.
    [[NSNotificationCenter defaultCenter]
        addObserver:self
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
        BOOL allFavorite =
            hasSelection && [self allContactsAreFavorite:selected];
        NSString *starName = allFavorite ? @"star.fill" : @"star";

        UIBarButtonItem *favorite = [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:starName]
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(favoriteSelected)];
        favorite.accessibilityLabel = @"Favorite";
        favorite.enabled = hasSelection;

        UIBarButtonItem *delete = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                 target:self
                                 action:@selector(deleteSelected)];
        delete.tintColor = UIColor.systemRedColor;
        delete.accessibilityLabel = @"Delete";
        delete.enabled = hasSelection;
        self.deleteBarButtonItem = delete;

        // Trash appears first (trailing-most), Favorite to its left.
        self.navigationItem.rightBarButtonItems = @[ delete, favorite ];
        return;
    }

    self.deleteBarButtonItem = nil;
    UIBarButtonItem *sortItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"arrow.up.arrow.down"]
                 menu:[self makeSortMenu]];
    sortItem.accessibilityLabel = @"Sort";

    NSMutableArray<UIBarButtonItem *> *rightItems = [NSMutableArray array];
    if (self.showsAddButton) {
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
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
    UIAction *asc =
        [UIAction actionWithTitle:@"Name (A-Z)"
                            image:[UIImage systemImageNamed:@"arrow.up"]
                       identifier:nil
                          handler:^(__kindof UIAction *_Nonnull action) {
                            weakSelf.ascending = YES;
                            [weakSelf reloadContacts];
                          }];
    UIAction *desc =
        [UIAction actionWithTitle:@"Name (Z-A)"
                            image:[UIImage systemImageNamed:@"arrow.down"]
                       identifier:nil
                          handler:^(__kindof UIAction *_Nonnull action) {
                            weakSelf.ascending = NO;
                            [weakSelf reloadContacts];
                          }];
    asc.state = self.ascending ? UIMenuElementStateOn : UIMenuElementStateOff;
    desc.state = self.ascending ? UIMenuElementStateOff : UIMenuElementStateOn;
    return [UIMenu menuWithTitle:@"Sort" children:@[ asc, desc ]];
}

- (void)configureSearch {
    self.searchController =
        [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search name or number";
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

#pragma mark - Data

- (void)reloadContacts {
    if (self.store == nil) {
        return;
    }
    self.items = [self.store contactsMatchingSearch:self.searchText ?: @""
                                      favoritesOnly:self.favoritesOnly
                                          ascending:self.ascending];
    [self.tableView reloadData];
    [self updateEmptyState];
}

/// Shows a centered placeholder when the list has no rows (empty list or no search hits).
- (void)updateEmptyState {
    if (self.items.count > 0) {
        self.tableView.backgroundView = nil;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return;
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    BOOL isSearching = self.searchText.length > 0;
    NSString *symbolName;
    NSString *title;
    NSString *subtitle;

    if (isSearching) {
        symbolName = @"magnifyingglass";
        title = @"No Results";
        subtitle = @"Try a different name, number, or email.";
    } else if (self.favoritesOnly) {
        symbolName = @"star";
        title = @"No Favorites";
        subtitle = @"Mark contacts as favorites to see them here.";
    } else {
        symbolName = @"person.3";
        title = @"No Contacts";
        subtitle = @"Tap + to add your first contact.";
    }

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:44
                                                        weight:UIImageSymbolWeightRegular];
    UIImageView *icon = [[UIImageView alloc]
        initWithImage:[[UIImage systemImageNamed:symbolName withConfiguration:config]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    icon.tintColor = UIColor.tertiaryLabelColor;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    titleLabel.textColor = UIColor.secondaryLabelColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = subtitle;
    subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    subtitleLabel.textColor = UIColor.tertiaryLabelColor;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *stack = [[UIStackView alloc]
        initWithArrangedSubviews:@[ icon, titleLabel, subtitleLabel ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack setCustomSpacing:16 afterView:icon];

    UIView *container = [[UIView alloc] initWithFrame:self.tableView.bounds];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [container addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [icon.widthAnchor constraintEqualToConstant:56],
        [icon.heightAnchor constraintEqualToConstant:56],
        [stack.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-40],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor constant:32],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-32],
    ]];

    self.tableView.backgroundView = container;
}

#pragma mark - Editing (Favorite / Delete)

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
        if (!contact.isFavorite) {
            return NO;
        }
    }
    return contacts.count > 0;
}

- (void)deleteSelected {
    NSArray<NSString *> *ids = [self selectedContactIDs];
    if (ids.count == 0) { return; }
    NSString *message = ids.count == 1
        ? @"This contact will be permanently deleted."
        : [NSString stringWithFormat:@"%lu contacts will be permanently deleted.", (unsigned long)ids.count];
    // Anchor the sheet to the trash button in the nav bar.
    [self confirmDeleteWithIDs:ids
                         title:@"Are you sure you want to delete?"
                       message:message
                 barButtonItem:self.deleteBarButtonItem
                    sourceView:nil
                    sourceRect:CGRectZero];
}

- (void)confirmDeleteWithIDs:(NSArray<NSString *> *)ids
                       title:(NSString *)title
                     message:(NSString *)message
               barButtonItem:(UIBarButtonItem *)barButtonItem
                  sourceView:(UIView *)sourceView
                  sourceRect:(CGRect)sourceRect {
    if (ids.count == 0) {
        return;
    }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleActionSheet];

    NSString *deleteTitle =
        ids.count == 1 ? @"Delete Contact" : @"Delete Contacts";
    [alert addAction:[UIAlertAction
                         actionWithTitle:deleteTitle
                                   style:UIAlertActionStyleDestructive
                                 handler:^(__unused UIAlertAction *action) {
                                   [self.store deleteContactsWithIDs:ids];
                                   if (self.isEditing) {
                                       [self setEditing:NO animated:YES];
                                   }
                                 }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    // Anchor: trash button (edit mode) or the swiped contact row/action view.
    UIPopoverPresentationController *popover = alert.popoverPresentationController;
    if (barButtonItem != nil) {
        popover.barButtonItem = barButtonItem;
    } else if (sourceView != nil) {
        popover.sourceView = sourceView;
        popover.sourceRect = CGRectIsEmpty(sourceRect) ? sourceView.bounds : sourceRect;
    } else {
        popover.sourceView = self.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                        CGRectGetMidY(self.view.bounds), 1, 1);
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)favoriteSelected {
    NSArray<ContactDTO *> *selected = [self selectedContacts];
    if (selected.count == 0) {
        return;
    }
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

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kCellID
                                        forIndexPath:indexPath];
    ContactDTO *contact = self.items[indexPath.row];

    UIListContentConfiguration *content =
        [UIListContentConfiguration subtitleCellConfiguration];
    content.text =
        contact.fullName.length > 0 ? contact.fullName : @"(No name)";
    content.secondaryText = contact.phoneNumber;
    CGFloat avatarSize = 40.0;
    content.image = [self avatarForContact:contact size:avatarSize];
    // Reserve a fixed slot so placeholder and photo avatars share the same
    // leading inset and text alignment.
    content.imageProperties.reservedLayoutSize =
        CGSizeMake(avatarSize, avatarSize);
    content.imageProperties.maximumSize = CGSizeMake(avatarSize, avatarSize);
    content.imageProperties.cornerRadius = avatarSize / 2.0;
    cell.contentConfiguration = content;

    // Favorite indicator on the trailing side.
    if (contact.isFavorite) {
        UIImageView *star = [[UIImageView alloc]
            initWithImage:[UIImage systemImageNamed:@"star.fill"]];
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
    // Draw into the same fixed size×size canvas as real photos so the
    // placeholder aligns (SF Symbols have optical padding otherwise).
    return [self placeholderAvatarWithSize:size];
}

/// Renders the person SF Symbol into a size×size bitmap, matching photo
/// avatars.
- (UIImage *)placeholderAvatarWithSize:(CGFloat)size {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration
        configurationWithPointSize:size
                            weight:UIImageSymbolWeightRegular
                             scale:UIImageSymbolScaleLarge];
    UIImage *symbol = [UIImage systemImageNamed:@"person.crop.circle.fill"
                              withConfiguration:config];
    // Bake the tint into the bitmap so it stays visible after rasterizing.
    UIImage *tinted =
        [symbol imageWithTintColor:UIColor.tertiaryLabelColor
                     renderingMode:UIImageRenderingModeAlwaysOriginal];

    CGFloat scale = self.traitCollection.displayScale;
    if (scale <= 0) { scale = 2.0; }
    CGSize canvas = CGSizeMake(size, size);

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = scale;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:canvas format:format];

    return [renderer
        imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull ctx) {
          // Fill the entire canvas so layout treats this like a photo avatar.
          [tinted drawInRect:CGRectMake(0, 0, size, size)];
        }];
}

// Returns a square, center-cropped copy of the image scaled to size x size.
- (UIImage *)squareImage:(UIImage *)image targetSize:(CGFloat)size {
    CGFloat scale = self.traitCollection.displayScale;
    if (scale <= 0) { scale = 2.0; }
    CGSize pixelSize = CGSizeMake(size, size);

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = scale;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:pixelSize format:format];

    return [renderer
        imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull ctx) {
          CGFloat side = MIN(image.size.width, image.size.height);
          CGFloat originX = (image.size.width - side) / 2.0;
          CGFloat originY = (image.size.height - side) / 2.0;

          // Scale the cropped square up to fill the target, keeping it
          // centered.
          CGFloat drawScale = size / side;
          CGRect drawRect = CGRectMake(
              -originX * drawScale, -originY * drawScale,
              image.size.width * drawScale, image.size.height * drawScale);
          [image drawInRect:drawRect];
        }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        // Multi-select: refresh the Favorite/Delete buttons for the new
        // selection.
        [self updateRightBarButtonItems];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ContactDTO *contact = self.items[indexPath.row];
    [self.delegate contactsListDidSelectContactID:contact.id];
}

- (void)tableView:(UITableView *)tableView
    didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        [self updateRightBarButtonItems];
    }
}

// Swipe-to-delete in normal mode.
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:
        (NSIndexPath *)indexPath {
    ContactDTO *contact = self.items[indexPath.row];
    if (contact.isUserProfile) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    UIContextualAction *delete = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive
                            title:@"Delete"
                          handler:^(UIContextualAction *action,
                                    UIView *sourceView,
                                    void (^completionHandler)(BOOL)) {
                            // Prefer the full contact row as the anchor so the
                            // sheet originates from the list element.
                            UITableViewCell *cell =
                                [weakSelf.tableView cellForRowAtIndexPath:indexPath];
                            UIView *anchor = cell ?: sourceView;
                            CGRect rect = cell != nil ? cell.bounds : sourceView.bounds;
                            [weakSelf confirmDeleteWithIDs:@[ contact.id ]
                                                     title:@"Are you sure you want to delete?"
                                                   message:@"This contact will be permanently deleted."
                                             barButtonItem:nil
                                                sourceView:anchor
                                                sourceRect:rect];
                            completionHandler(YES); // closes swipe; delete only on confirm
                          }];
    return [UISwipeActionsConfiguration configurationWithActions:@[ delete ]];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController {
    self.searchText = searchController.searchBar.text ?: @"";
    [self reloadContacts];
}

@end
