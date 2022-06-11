//
//  JSExecutor.m
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "JSExecutor.h"
#import <objc/runtime.h>

@implementation JSExecutor

- (void)excution {
    if (self.executionStatus != JSExecutStatusNone) return;
    _executionStatus = JSExecutStatusExecuting;
    
    
}
- (void)cancel {
    _executionStatus = JSExecutStatusCancel;
}
- (BOOL)excutable {
    return YES;
}

/// 操作结束后 需要调用这个方法
- (void)completed:(nullable id) result error:(nullable NSError *)error {
    _executionStatus = JSExecutStatusFinish;
    self.response = result;
    self.error = error;
    if ([self.delegate respondsToSelector:@selector(executionDidFinish:error:)]) {
        [self.delegate executionDidFinish:self error:error];
    }
}
@end

@implementation JSExecutor (Completion)

- (void)setResponse:(id)response {
    objc_setAssociatedObject(self, @selector(response), response, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)response {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setError:(NSError *)error {
    objc_setAssociatedObject(self, @selector(error), error, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSError *)error {
    return objc_getAssociatedObject(self, _cmd);
}
@end
