#import "LoginController.h"
#import "AppDelegate.h"
#import "UIButton+CZ.h"
#import "MBProgressHUD+HM.h"
#import "LoginTool.h"
#import "MRCommon.h"

@interface LoginController ()

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UITextField *userField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginBtn.backgroundColor = [UIColor grayColor];
    
    self.userField.text     = [LoginTool user];
    self.passwordField.text = [LoginTool pwd];
    [self textChange];
}

- (IBAction)textChange {
    BOOL enabled = (self.userField.text.length > 0 && self.passwordField.text.length > 0);
    self.loginBtn.enabled = enabled;
    
    if (enabled) {
        self.loginBtn.backgroundColor = [UIColor blueColor];
    } else {
        self.loginBtn.backgroundColor = [UIColor grayColor];
    }
}

- (IBAction)login {
    NSString *user = [self.userField.text stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceCharacterSet]];
    NSString *domain = @"telegram.universal-translation-services.com";

    [LoginTool saveLoginWithUser:user pwd:password domain:domain];
    
    id obj = [UIApplication sharedApplication].delegate;
    AppDelegate *appDelegate = obj;
    [self.view endEditing:YES];
    appDelegate.userRegister = NO;
    __weak UIView *hudView = self.view;

    [MBProgressHUD showMessage:@"Logging in..." toView:hudView];
    [appDelegate xmppLogin:^(XMPPResultType resultType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:hudView];

            switch (resultType) {
                case XMPPResultTypeLoginFailure:
                    [MBProgressHUD showError:@"Username or password is incorrect"];
                break;

                case XMPPResultTypeNetError:
                    [MBProgressHUD showError:@"No internet. Check internet connection"];
                break;

                case XMPPResultTypeUnknowDomain:
                   [MBProgressHUD showError:@"Unknown domain or internet problem"];
                break;
                    
                case XMPPResultTypeConnectionRefused:
                    [MBProgressHUD showError:@"Connection Refused"];
                break;

                default: break;
            }
        });
    }];
}

@end
