#import <UIKit/UIKit.h>

@class XMPPJID;

@interface ChatController : UIViewController

@property (nonatomic, strong) XMPPJID *friendJid;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end
