//
//  JSAsyncOperation.m
//  JSBasicFramework
//
//  Created by json on 2022/5/12.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "JSAsyncOperation.h"
#import <libkern/OSAtomic.h>
#import "JSExecutor.h"
#import <UIKit/UIKit.h>

@interface JSAsyncOperation ()<JSExecutorDelegate>

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock; // 递归锁
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskID;

@end

@implementation JSAsyncOperation
@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

/// Network thread entry point.
+ (void)_networkThreadMain:(id)object {
    /// 线程保活
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.ibireme.jskit.async.excution"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

/// Global image request network thread, used by NSURLConnection delegate.
+ (NSThread *)_networkThread {
    static NSThread *thread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(_networkThreadMain:) object:nil];
        if ([thread respondsToSelector:@selector(setQualityOfService:)]) {
            thread.qualityOfService = NSQualityOfServiceBackground;
        }
        [thread start];
    });
    return thread;
}

+ (dispatch_queue_t) _excutionQueue {
    #define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
                queues[i] = dispatch_queue_create("com.ibireme.jskit.decode", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.ibireme.jskit.decode", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
            }
        }
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    int32_t cur = OSAtomicIncrement32(&counter);
#pragma clang diagnostic pop
    
    if (cur < 0) cur = -cur;
    return queues[(cur) % queueCount];
}
- (instancetype) initWithExecutor:(JSExecutor *) executor completion:(AsyncCompletion) completoin {
    if (self = [super init]) {
        _executor = executor;
        _executor.delegate = self;
        _asyncCompletion = [completoin copy];
        _executing = NO;
        _finished = NO;
        _cancelled = NO;
        _taskID = UIBackgroundTaskInvalid;
        // 递归锁
        _lock = [NSRecursiveLock new];
        
    }
    return self;
}
- (void)_endBackgroundTask {
    [_lock lock];
    if (_taskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_taskID];
        _taskID = UIBackgroundTaskInvalid;
    }
    [_lock unlock];
}
#pragma mark - Runs in operation thread

- (void)_finish {
    self.executing = NO;
    self.finished = YES;
    [self _endBackgroundTask];
}


- (void)_startOperation {
    if ([self isCancelled]) return;
    [self performSelector:@selector(_startExcution:) onThread:[self.class _networkThread] withObject:nil waitUntilDone:NO];
    
}


- (void)_startExcution:(id)object {
    if ([self isCancelled]) return;
    @autoreleasepool {
        // request image from web
        BOOL executable = YES;
        [_lock lock];
        executable = [self.executor excutable];
        [_lock unlock];
        
        if (!executable) {
            [_lock lock];
            if (![self isCancelled]) {
                if (self.asyncCompletion) self.asyncCompletion(self.executor);
                [self _finish];
            }
            [_lock unlock];
            return;
            
        }
        
        [_lock lock];
        if (![self isCancelled]) {
            [self.executor excution];
        }
        [_lock unlock];
    }
}

- (void) _cancelOperation {
    @autoreleasepool {
        [_executor cancel];
        JSExecutor *e = _executor;
        _executor = nil;
        if (_asyncCompletion) _asyncCompletion(e);
        [self _endBackgroundTask];
    }
}

- (void)cancel {
    [_lock lock];
    if (![self isCancelled]) {
        [super cancel];
        self.cancelled = YES;
        if ([self isExecuting]) {
            self.executing = NO;
            [self performSelector:@selector(_cancelOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
        }
        if (self.started) {
            self.finished = YES;
        }
    }
    [_lock unlock];
}
//MARK: 获取到任务执行结果
- (void)executionDidFinish:(JSExecutor *) executor error:(nullable NSError *)error {
    @autoreleasepool {
        [_lock lock];
        if (![self isCancelled]) {
            NSLog(@"获取到执行任务结果 %@", executor);
            if (self.asyncCompletion) self.asyncCompletion(self.executor);
            [self _finish];
        }
        [_lock unlock];
    }
}
#pragma mark - Override NSOperation

- (void)start {
    @autoreleasepool {
        [_lock lock];
        self.started = YES;
        if ([self isCancelled]) {
            [self performSelector:@selector(_cancelOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
            self.finished = YES;
        } else if ([self isReady] && ![self isFinished] && ![self isExecuting]) {
            if (!_executor) {
                self.finished = YES;
                if (_asyncCompletion) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:@{NSLocalizedDescriptionKey:@"_executor in nil"}];
                    _executor.error = error;
                    _asyncCompletion(_executor);
                }
            } else {
                self.executing = YES;
                [self performSelector:@selector(_startOperation) onThread:[[self class] _networkThread] withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
                
            }
        }
        [_lock unlock];
    }
}



- (void)setExecuting:(BOOL)executing {
    [_lock lock];
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
    [_lock unlock];
}

- (BOOL)isExecuting {
    [_lock lock];
    BOOL executing = _executing;
    [_lock unlock];
    return executing;
}

- (void)setFinished:(BOOL)finished {
    [_lock lock];
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
    [_lock unlock];
}

- (BOOL)isFinished {
    [_lock lock];
    BOOL finished = _finished;
    [_lock unlock];
    return finished;
}

- (void)setCancelled:(BOOL)cancelled {
    [_lock lock];
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = cancelled;
        [self didChangeValueForKey:@"isCancelled"];
    }
    [_lock unlock];
}

- (BOOL)isCancelled {
    [_lock lock];
    BOOL cancelled = _cancelled;
    [_lock unlock];
    return cancelled;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"isExecuting"] ||
        [key isEqualToString:@"isFinished"] ||
        [key isEqualToString:@"isCancelled"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p ",self.class, self];
    [string appendFormat:@" executing:%@", [self isExecuting] ? @"YES" : @"NO"];
    [string appendFormat:@" finished:%@", [self isFinished] ? @"YES" : @"NO"];
    [string appendFormat:@" cancelled:%@", [self isCancelled] ? @"YES" : @"NO"];
    [string appendString:@">"];
    return string;
}
- (void)dealloc {
    [_lock lock];
    if (_taskID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_taskID];
        _taskID = UIBackgroundTaskInvalid;
    }
    if ([self isExecuting]) {
        self.cancelled = YES;
        self.finished = YES;
        if (self.executor) {
            [self.executor cancel];
        }
        if (self.asyncCompletion) {
            @autoreleasepool {
                self.asyncCompletion(self.executor);
            }
        }
    }
    [_lock unlock];
}
@end
