#import "RosterController.h"
#import "AppDelegate.h"
#import "ChatController.h"
#import "LoginTool.h"
#define Delegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface RosterController () <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *_resultContr;
    NSString* highlightFriend;
    BOOL isChatting;
}

@property (nonatomic, strong) NSArray *friends;

- (IBAction)addFriend:(id)sender;

@end

@implementation RosterController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadFriends];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerAction:) name:@"ReloadAppDelegateTable" object:nil];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTable)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    isChatting = FALSE;
}

- (void)triggerAction:(NSNotification *)notification {
    [self loadFriends];

    if (!isChatting) {
        NSString* friend = notification.userInfo[@"friend"];
        if ([friend length] != 0) {
            highlightFriend = friend;
        } else {
            highlightFriend = nil;
        }

        [self.tableView reloadData];
    }
}

- (void)refreshTable {
    [self loadFriends];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)loadFriends {
    NSManagedObjectContext *context = Delegate.rosterStroage.mainThreadManagedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors = @[sort];

    _resultContr = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:@"sectionNum" cacheName:nil];
    _resultContr.delegate = self;

    NSError *error = nil;
    [_resultContr performFetch:&error];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _resultContr.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {   
    id<NSFetchedResultsSectionInfo> groupInfo = _resultContr.sections[section];
    return [groupInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> groupInfo = _resultContr.sections[section];
    
    NSInteger state = [[groupInfo indexTitle] integerValue];
    switch (state) {
        case 0:
            return @"Online";
        break;

        case 1:
            return @"Leave";
        break;

        case 2:
            return @"Offline";
        break;

        default:
            return @"Unknown";
        break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"FriendCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    XMPPUserCoreDataStorageObject *friend = [_resultContr objectAtIndexPath:indexPath];
    cell.textLabel.text = friend.displayName;
    
    if ([friend.jidStr isEqualToString:highlightFriend] && highlightFriend != nil) {
        cell.imageView.image = [UIImage imageNamed:@"alert"];
        isChatting = TRUE;
    }

    return cell;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        XMPPUserCoreDataStorageObject *friend = [_resultContr objectAtIndexPath:indexPath];
        [Delegate.roster removeUser:friend.jid];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *selectedCell=[tableView cellForRowAtIndexPath:indexPath];
    selectedCell.imageView.image = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath* index= [self.tableView indexPathForSelectedRow];

    XMPPUserCoreDataStorageObject *friend = [_resultContr objectAtIndexPath:index];

    id destVc = segue.destinationViewController;
    if ([destVc isKindOfClass:[ChatController class] ]) {
        ChatController *chatVc = destVc;
        chatVc.friendJid = friend.jid;
    }
}

- (IBAction)addFriend:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add friend" message:@"Enter friend username:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeDefault;
    [alert show];
}

- (void)viewDidAppear:(BOOL)animated {
    isChatting = FALSE;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *user = [alertView textFieldAtIndex:0].text;
    
    // Проверка на символ @ - если есть, показывать ошибку
    NSRange range = [user rangeOfString:@"@"];
    if (range.location != NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Username cannot consists @ symbol" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    NSString *domain = [LoginTool domain];
    NSString *userJid = [NSString stringWithFormat:@"%@@%@",user,domain];
    XMPPJID *friendJid = [XMPPJID jidWithString:userJid];
    
    BOOL exist = [Delegate.rosterStroage userExistsWithJID:friendJid xmppStream:Delegate.xmppStream];
    if (exist) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Friend with this username already added" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [Delegate.roster subscribePresenceToUser:friendJid];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
