//
//  _JSAsyncExecutionSetter.m
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "_JSAsyncExecutionSetter.h"
#import <libkern/OSAtomic.h>

@interface _JSAsyncExecutionSetter ()

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) JSExecutor *executor;
@property (nonatomic, strong) NSOperation *operation;

@end

@implementation _JSAsyncExecutionSetter

- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    return self;
}

- (int32_t)setOperationWithSentinel:(int32_t)sentinel executor:(JSExecutor *)executor manager:(JSAsyncExecutionManager *)manager completioin:(AsyncCompletion)completion {
    if (sentinel != _sentinel) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:@{NSLocalizedDescriptionKey:@"sentinel != _sentinel"}];
        executor.error = error;
        if(completion) completion(executor);
        return _sentinel;
    }
    NSOperation *operation = [manager asyncWithExexut:executor completion:completion];
    if (!operation && completion) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"JSAsyncOperation create failed." };
        executor.error = [NSError errorWithDomain:@"com.ibireme.jskie.asyncOperation" code:-1 userInfo:userInfo];
        if(completion) completion(executor);
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (sentinel == _sentinel) {
        if (_operation) [_operation cancel];
        _operation = operation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        sentinel = OSAtomicIncrement32(&_sentinel);
#pragma clang diagnostic pop
    } else {
        [operation cancel];
    }
    dispatch_semaphore_signal(_lock);
    return sentinel;
}
- (int32_t)cancel {
    return [self cancelWithNewExecutor:nil];
}
- (int32_t)cancelWithNewExecutor:(JSExecutor *)executor {
    int32_t sentinel;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_operation) {
        [_operation cancel];
        _operation = nil;
    }
    _executor = executor;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    sentinel = OSAtomicIncrement32(&_sentinel);
#pragma clang diagnostic pop
    dispatch_semaphore_signal(_lock);
    return sentinel;
}
- (void)dealloc {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSAtomicIncrement32(&_sentinel);
#pragma clang diagnostic pop
    
    [_operation cancel];
}

/**
 * 保证任务在子线程 queue 里有序进行 - 串行执行
 */
+ (dispatch_queue_t)setterQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// 创建一个串行队列
        queue = dispatch_queue_create("com.ibireme.jskit.asyncOperation.setter", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    });
    return queue;
}

@end
