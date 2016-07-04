#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Cocoa/Cocoa.h>

#define M80NotificationPrefix   (@"m80_wechat_revoke")

@interface M80NotificationManager : NSObject<NSUserNotificationCenterDelegate>
@property (nonatomic,assign)  id<NSUserNotificationCenterDelegate> delegate;
@end

@implementation M80NotificationManager
+ (instancetype)sharedManager
{
    static M80NotificationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[M80NotificationManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
    }
    return self;
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    if ([notification.identifier hasPrefix:M80NotificationPrefix])
    {
        return YES;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(userNotificationCenter:shouldPresentNotification:)]) {
        
        return [_delegate userNotificationCenter:center
                       shouldPresentNotification:notification];
    }
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    if (_delegate && [_delegate respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)]) {
        [_delegate userNotificationCenter:center
                   didDeliverNotification:notification];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(nonnull NSUserNotification *)notification
{
    if (_delegate && [_delegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)]) {
        [_delegate userNotificationCenter:center
                  didActivateNotification:notification];
    }
}

@end

static void injection() {
    
    Class cls = NSClassFromString(@"MessageService");
    SEL sel = NSSelectorFromString(@"onRevokeMsg:");
    IMP emptyImp = imp_implementationWithBlock(^(id self, id arg) {
        
        NSString *msg = (NSString *)arg;
        NSRange begin = [msg rangeOfString:@"<session>"];
        NSRange end = [msg rangeOfString:@"</session>"];
        NSRange subRange = NSMakeRange(begin.location + begin.length,end.location - begin.location - begin.length);
        
        NSString *session = [msg substringWithRange:subRange];
        
        if ([session rangeOfString:@"@chatroom"].location != NSNotFound)
        
        {
            //Service Center
            Method methodMMServiceCenter = class_getClassMethod(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            IMP impMMSC = method_getImplementation(methodMMServiceCenter);
            id MMServiceCenter = impMMSC(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
            
            //group Storage
            id groupStorage = ((id (*)(id, SEL, id))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("GroupStorage"));
            
            id group = ((id (*)(id, SEL, NSString *))objc_msgSend)(groupStorage, @selector(GetGroupContact:),session);
            
            
            Ivar nicknameIvar = class_getInstanceVariable(objc_getClass("WCContactData"), "m_nsNickName");
            id groupName = object_getIvar(group, nicknameIvar);
            
            //能拿到群名才进行通知...
            if ([groupName isKindOfClass:[NSString class]] && [(NSString *)groupName length])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
                    userNotification.title = @"撤回通知";
                    userNotification.informativeText = [NSString stringWithFormat:@"群 %@ 中有人撤回了一条消息，快去看看吧",groupName];
                    userNotification.identifier = [NSString stringWithFormat:@"%@_%@",M80NotificationPrefix,[[NSUUID UUID] UUIDString]];
                    
                    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
                    
                    if (center.delegate != [M80NotificationManager sharedManager])
                    {
                        [M80NotificationManager sharedManager].delegate = center.delegate;
                        center.delegate = [M80NotificationManager sharedManager];
                    }
                    [center deliverNotification:userNotification];
                });
            }
            
        }
        
    });
    Method originMethod = class_getInstanceMethod(cls, sel);
    IMP originImp = class_replaceMethod(cls, sel, emptyImp, method_getTypeEncoding(originMethod));
    NSLog(@"[noRevoke] cls: %@, originImp: %p", cls, originImp);
}

__attribute__((constructor))
static void initializer(void) {
    NSLog(@"[noRevoke] start");
    injection();
}
