#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
                    userNotification.identifier = [[NSUUID UUID] UUIDString];
                    
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
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
