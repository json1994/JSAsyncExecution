//
//  JSAsyncExecutionManager.m
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "JSAsyncExecutionManager.h"

@implementation JSAsyncExecutionManager

+ (instancetype)sharedManager {
    static JSAsyncExecutionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSOperationQueue *queue = [NSOperationQueue new];
        if ([queue respondsToSelector:@selector(setQualityOfService:)]) {
            queue.qualityOfService = NSQualityOfServiceBackground;
        }
        manager = [[self alloc] initWithQueue:queue];
    });
    return manager;
}
- (instancetype)init {
    @throw [NSException exceptionWithName:@"JSAsyncExecutionManager init error" reason:@"Use the designated initializer to init." userInfo:nil];
    return [self initWithQueue:nil];
}
- (instancetype)initWithQueue:(NSOperationQueue *)queue {
    if (self = [super init]) {
        _queue = queue;
    }
    return self;
}
- (JSAsyncOperation *)asyncWithExexut:(JSExecutor *)executor completion:(AsyncCompletion)completion {
    JSAsyncOperation *operation = [[JSAsyncOperation alloc] initWithExecutor:executor completion:completion];
    if (operation) {
        NSOperationQueue *queue = _queue;
        if (queue) {
            [queue addOperation:operation];
        } else {
            [operation start];
        }
    }
    return operation;
}
@end
