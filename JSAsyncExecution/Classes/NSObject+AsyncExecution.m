//
//  NSObject+AsyncExecution.m
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "NSObject+AsyncExecution.h"
#import "_JSAsyncExecutionSetter.h"
#import <objc/runtime.h>

static int _JSKitAsyncSetterKey;

@implementation NSObject (AsyncExecution)

- (JSExecutor *)executor {
    _JSAsyncExecutionSetter *setter = objc_getAssociatedObject(self, &_JSKitAsyncSetterKey);
    return setter.executor;
}

- (void)setAsyncExector:(JSExecutor *)executor completion:(AsyncCompletion)completion {
    JSAsyncExecutionManager *manager = [JSAsyncExecutionManager sharedManager];
    
    _JSAsyncExecutionSetter *setter = objc_getAssociatedObject(self, &_JSKitAsyncSetterKey);
    if (!setter) {
        setter = [_JSAsyncExecutionSetter new];
        objc_setAssociatedObject(self, &_JSKitAsyncSetterKey, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    int32_t sentinel = [setter cancelWithNewExecutor:executor];
    if (!executor) {
        return;
    }
    __weak typeof(self) _self = self;
    dispatch_async([_JSAsyncExecutionSetter setterQueue], ^{
        __block int32_t newSentinel = 0;
        __block __weak typeof(setter) weakSetter = nil;
        
        AsyncCompletion _completion = ^(JSExecutor *aExector) {
            __strong typeof(_self) self = _self;
            BOOL sentinelChanged = weakSetter && weakSetter.sentinel != newSentinel;
            [self asyncExcutionDidFinish:aExector sentinelChanged:sentinelChanged];
            
            if (completion) {
                if (sentinelChanged) {
                    completion(nil);
                }else {
                    completion(aExector);
                }
            }
            
            
        };
        newSentinel = [setter setOperationWithSentinel:sentinel executor:executor manager:manager completioin:_completion];
        weakSetter = setter;
    });
}


- (void)asyncExcutionDidFinish:(JSExecutor *) executor sentinelChanged:(BOOL) change{
    
}
@end
