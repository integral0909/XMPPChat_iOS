#import <Foundation/Foundation.h>

#define kUserKey @"user"
#define kPwdKey @"pwd"
#define kDomainKey @"domain"
#define kIsLoginKey @"isLogin"

@interface LoginTool : NSObject

+ (void)saveLoginWithUser:(NSString *)user pwd:(NSString *)pwd domain:(NSString *)domain;

+ (NSString *)user;
+ (NSString *)pwd;
+ (NSString *)domain;

+ (void)removeLoginInfo;
+ (void)setLoginStatus:(BOOL)login;
+ (BOOL)loginStatus;

@end
