#import "LoginTool.h"

@implementation LoginTool

+ (void)saveLoginWithUser:(NSString *)user pwd:(NSString *)pwd domain:(NSString *)domain {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:user forKey:kUserKey];
    [defaults setObject:pwd forKey:kPwdKey];
    [defaults setObject:domain forKey:kDomainKey];

    [defaults synchronize];
}

+ (NSString *)user {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserKey];
}

+ (NSString *)pwd {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kPwdKey];
}

+ (NSString *)domain {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDomainKey];
}

+ (void)removeLoginInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kUserKey];
    [defaults removeObjectForKey:kPwdKey];
    [defaults removeObjectForKey:kDomainKey];
    [defaults synchronize];
}

+ (void)setLoginStatus:(BOOL)login {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:login forKey:kIsLoginKey];
    [defaults synchronize];
}

+ (BOOL)loginStatus {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsLoginKey];
}

@end
