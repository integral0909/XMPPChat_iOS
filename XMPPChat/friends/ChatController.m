#import "ChatController.h"
#import "AppDelegate.h"
#import "LoginTool.h"
#import "NSDate+CZ.h"
#define Delegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface ChatController () <UITableViewDataSource, UITableViewDelegate ,UITextFieldDelegate, NSFetchedResultsControllerDelegate ,UINavigationControllerDelegate> {
    NSFetchedResultsController *_resultControler;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)sendMsg:(UIButton *)sender;

@end

@implementation ChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpdata];
    
    self.title = self.friendJid.bare;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_resultControler.fetchedObjects.count > 5) {
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height -     self.tableView.frame.size.height);
        [self.tableView setContentOffset:offset animated:YES];
    }
}

- (void)setUpdata {
    NSManagedObjectContext *context = Delegate.msgStorage.mainThreadManagedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sort];

    NSString *friendJid = self.friendJid.bare;
    NSString *selfJib   = Delegate.xmppStream.myJID.bare;

    NSPredicate *pre = [NSPredicate predicateWithFormat:@"bareJidStr = %@ AND streamBareJidStr = %@",friendJid,selfJib];
    request.predicate = pre;
    
    _resultControler = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultControler.delegate = self;
    [_resultControler performFetch:nil];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];

    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:_resultControler.fetchedObjects.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _resultControler.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"ChatCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];

    XMPPMessageArchiving_Message_CoreDataObject *msg = _resultControler.fetchedObjects[indexPath.row];

    UITextView* textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 15, 50)];
    textView.text = msg.body;
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.editable = NO;
    textView.selectable = YES;
    [textView setFont:[UIFont systemFontOfSize:16]];
    
    if (msg.isOutgoing) {
        textView.textAlignment = NSTextAlignmentRight;
        textView.textColor = [UIColor grayColor];
    } else {
        textView.textAlignment = NSTextAlignmentLeft;
        textView.textColor = [UIColor blackColor];
    }

    [cell addSubview:textView];
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = textField.text;
  
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
    [msg addBody:text];

    [Delegate.xmppStream sendElement:msg];

    textField.text = nil;
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.view endEditing:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.3];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-250., self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.3];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+250., self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
}

- (IBAction)sendMsg:(UIButton *)sender {
    NSString *text = _textField.text;
    
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
    [msg addBody:text];
    
    [Delegate.xmppStream sendElement:msg];
    
    _textField.text = nil;
}

@end

