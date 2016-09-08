#import <UIKit/UIKit.h>
#import "XMPPFramework.h"

typedef enum {
    XMPPResultTypeLogining,
    XMPPResultTypeLoginSuccuess,
    XMPPResultTypeLoginFailure,
    XMPPResultTypeNetError,
    XMPPResultTypeUnknowDomain,
    XMPPResultTypeConnectionRefused,
    XMPPResultTypeRegisterSuccess,
    XMPPResultTypeRegisterFailure
} XMPPResultType;

typedef void (^XMPPResultBlock)(XMPPResultType resultType);

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong,readonly) XMPPvCardTempModule *vCardModule; 
@property (nonatomic, strong,readonly) XMPPStream *xmppStream;

@property (nonatomic, strong,readonly)XMPPRoster *roster;
@property (nonatomic, strong,readonly)XMPPRosterCoreDataStorage *rosterStroage;
@property (nonatomic, strong,readonly)XMPPMessageArchiving *msgArching;
@property (nonatomic, strong,readonly)XMPPMessageArchivingCoreDataStorage *msgStorage;
@property (nonatomic, assign,getter = isUserRegister) BOOL userRegister;

- (void)xmppLogin:(XMPPResultBlock)resultBlock;
- (void)xmppLogout;
- (void)xmppRegister:(XMPPResultBlock)resultBlock;

@end
