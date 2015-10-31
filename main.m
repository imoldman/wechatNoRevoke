#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void injection() {
    Class cls = NSClassFromString(@"MessageService");
    SEL sel = NSSelectorFromString(@"onRevokeMsg:");
    IMP emptyImp = imp_implementationWithBlock(^(id self, id arg) {});
    Method originMethod = class_getInstanceMethod(cls, sel);
    IMP originImp = class_replaceMethod(cls, sel, emptyImp, method_getTypeEncoding(originMethod));
    NSLog(@"[noRevoke] cls: %@, originImp: %p", cls, originImp);
}

__attribute__((constructor))
static void initializer(void) {
    NSLog(@"[noRevoke] start");
    injection();
}
