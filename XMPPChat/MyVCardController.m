#import "MyVCardController.h"
#import "AppDelegate.h"
#import "XMPPvCardTemp.h"
#define Delegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface MyVCardController () <UINavigationControllerDelegate> {
    UITableViewCell *selectedCell;
}

@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *jidLabel;
@property (weak, nonatomic) IBOutlet UILabel *appInfo;

- (IBAction)logout:(id)sender;

@end

@implementation MyVCardController

- (void)viewDidLoad {
    _appInfo.text = [NSString stringWithFormat:@"%@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    [super viewDidLoad];
    [self loadVCard];
}

- (void)loadVCard {
    XMPPvCardTemp *myCard = Delegate.vCardModule.myvCardTemp;

    self.nickNameLabel.text = myCard.nickname;
    self.jidLabel.text = Delegate.xmppStream.myJID.bare;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    int cellTag = (int)selectedCell.tag;
    
    if (cellTag == 2) {
        return;
    } else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Username" message:@"Enter your username:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *alertTextField = [alert textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeDefault;
        alertTextField.placeholder = self.nickNameLabel.text;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        self.nickNameLabel.text = [alertView textFieldAtIndex:0].text;
        [self editVCardViewControllerDidFinishChange];
    }
}

- (IBAction)logout:(id)sender {
    [Delegate xmppLogout];
}

- (void)editVCardViewControllerDidFinishChange {
    XMPPvCardTemp *myCard = Delegate.vCardModule.myvCardTemp;
    myCard.nickname = self.nickNameLabel.text;

    [Delegate.vCardModule updateMyvCardTemp:myCard];
}

@end
