#import "ChatController.h"
#import "AppDelegate.h"
#import "LoginTool.h"
#import "MRCommon.h"

#import "JCNotificationCenter.h"
#import "JCNotificationBannerPresenterIOS7Style.h"

#define Delegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate () <XMPPStreamDelegate, NSFetchedResultsControllerDelegate> {
    XMPPResultBlock _resultBlock;
    XMPPReconnect *_reconnect;
    XMPPvCardCoreDataStorage *_vCardStorage;
    XMPPvCardAvatarModule *_avatarModule;
    NSFetchedResultsController *_resultControler;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   [self setupXmmpStream];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    
    if ([LoginTool loginStatus]) {
        UIStoryboard *storybard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UITabBarController *tabVc = [storybard  instantiateInitialViewController];
        self.window.rootViewController = tabVc;
    }
    
    [self connectToHost];

    NSManagedObjectContext *context = Delegate.msgStorage.mainThreadManagedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sort];
    
    _resultControler = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    _resultControler.delegate = self;
    [_resultControler performFetch:nil];
    
    return YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    XMPPMessageArchiving_Message_CoreDataObject *msg = _resultControler.fetchedObjects[_resultControler.fetchedObjects.count - 1];

    NSDictionary* userInfo;
    if (!msg.isOutgoing) {
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterIOS7Style new];
            NSString* title = msg.bareJid.bare;
            NSString* alert = msg.body;
            
            [JCNotificationCenter enqueueNotificationWithTitle:title message:alert tapHandler:nil];
        }
        
        userInfo = @{@"friend": msg.bareJid.bare};
    } else {
        userInfo = @{@"friend": @""};
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadAppDelegateTable" object:nil userInfo:userInfo];
}

#pragma mark xmppStream

- (void)setupXmmpStream {
    NSAssert(_xmppStream==nil, @"_xmppStream");
    _xmppStream = [[XMPPStream alloc] init];
    _reconnect = [[XMPPReconnect alloc] init];

    [_reconnect activate:_xmppStream];
    
    _vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _vCardModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
    [_vCardModule activate:_xmppStream];
    
    _avatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCardModule];
    [_avatarModule activate:_xmppStream];
    
    _rosterStroage = [[XMPPRosterCoreDataStorage alloc] init];
    _roster = [[XMPPRoster alloc] initWithRosterStorage:_rosterStroage];
    [_roster activate:_xmppStream];
    _msgStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _msgArching = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_msgStorage];
    [_msgArching activate:_xmppStream];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (void)connectToHost {
    NSString *user = [LoginTool user];
    NSString *domain =[LoginTool domain];

    XMPPJID *myJid = [XMPPJID jidWithUser:user domain:domain resource:nil];
    _xmppStream.myJID = myJid;
    _xmppStream.hostPort = 5222;
    _xmppStream.hostName = domain;

    NSError *error = nil;
    BOOL success = [_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    if (success == NO) {
        HMLogInfo(@"%@",error);
    }

    [self postNotification:XMPPResultTypeLogining];
}

- (void)disconnectFromHost {

    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:presence];
    [_xmppStream disconnect];
}

- (void)goOnline {
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSString *pwd = [LoginTool pwd];
    NSError *error = nil;

    if (self.isUserRegister) {
        [_xmppStream registerWithPassword:pwd error:&error];
    } else {
       [_xmppStream authenticateWithPassword:pwd error:&error];
    }

    if (error) {
          HMLogInfo(@"%@",error);
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    if (error) {
        if (error.code == 8) {
            if (_resultBlock) {
                _resultBlock(XMPPResultTypeUnknowDomain);
            }
        } else if (error.code == 61) {
            if (_resultBlock) {
                _resultBlock(XMPPResultTypeConnectionRefused);
            }
        }

        [self removeLoginInfo];
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    [self goOnline];
    [self postNotification:XMPPResultTypeLoginSuccuess];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *storybard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        UITabBarController *tabVc = [storybard  instantiateInitialViewController];
        UIViewController* old=self.window.rootViewController;
        if(![old isKindOfClass:[tabVc class]]){
           self.window.rootViewController = tabVc;
        }
    });

   [LoginTool setLoginStatus:YES];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    [self removeLoginInfo];
    [self postNotification:XMPPResultTypeLoginFailure];

    if (_resultBlock) {
        _resultBlock(XMPPResultTypeLoginFailure);
    }
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    if (_resultBlock) {
        _resultBlock(XMPPResultTypeRegisterSuccess);
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error {
    if (_resultBlock) {
        _resultBlock(XMPPResultTypeRegisterFailure);
    }
}

//- (void)applicationWillResignActive:(UIApplication *)application
//{
//    if ([LoginTool loginStatus]) {
//        [self disconnectFromHost];
//    }
//}
//
//- (void)applicationDidBecomeActive:(UIApplication *)application
//{
//    if ([LoginTool loginStatus]) {
//        [self connectToHost];
//    }
//}

- (void)removeLoginInfo {
    [LoginTool removeLoginInfo];
}

- (void)xmppLogin:(XMPPResultBlock)resultBlock {
    _resultBlock = resultBlock;
        if (_xmppStream.isConnected) {
            [_xmppStream disconnect];
        }

    [self connectToHost];
}

- (void)xmppLogout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [LoginTool setLoginStatus:NO];
    [defaults synchronize];

    [self disconnectFromHost];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    self.window.rootViewController = storyboard.instantiateInitialViewController;
}

- (void)xmppRegister:(XMPPResultBlock)resultBlock {
    _resultBlock = resultBlock;

    [_xmppStream disconnect];
    [self connectToHost];
}

- (void)postNotification:(XMPPResultType)resultType {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{@"LoginStatus": @(resultType)};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginStatusNotification" object:nil userInfo:userInfo];
    });
    
}

- (void)dealloc {
    [self teardownStream];
}

- (void)teardownStream {
    [_xmppStream removeDelegate:self];
    [_reconnect deactivate];
    [_xmppStream disconnect];

    _xmppStream = nil;
    _reconnect = nil;
    _vCardModule = nil;
    _vCardStorage = nil;
    _avatarModule = nil;
    _roster = nil;
    _rosterStroage = nil;
    _msgArching = nil;
    _msgStorage = nil;
}

@end
